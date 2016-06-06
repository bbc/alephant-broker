require_relative "spec_helper"
require "alephant/broker"

describe Alephant::Broker::Application do
  include Rack::Test::Methods

  let(:config) do
    {
      :lookup_table_name => "test_table",
      :bucket_id         => "test_bucket",
      :path              => "bucket_path"
    }
  end

  let(:app) do
    described_class.new(
      Alephant::Broker::LoadStrategy::S3::Sequenced.new,
      config
    )
  end

  let(:content) do
    AWS::Core::Data.new(
      :content_type => "test/content",
      :content      => "Test",
      :meta         => {
        "head_ETag"          => "123",
        "head_Last-Modified" => "Mon, 11 Apr 2016 10:39:57 GMT"
      }
    )
  end

  let(:sequencer_double) do
    instance_double(
      "Alephant::Sequencer::Sequencer",
      :get_last_seen => "111"
    )
  end

  let(:lookup_location_double) do
    instance_double("Alephant::Lookup::Location", :location => "test/location")
  end
  let(:lookup_helper_double) do
    instance_double(
      "Alephant::Lookup::LookupHelper",
      :read => lookup_location_double
    )
  end

  let(:s3_double) { instance_double("Alephant::Storage", :get => content) }

  let(:not_modified_status_code) { Alephant::Broker::Response::Base::NOT_MODIFIED_STATUS_CODE }

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)
    allow(Alephant::Lookup).to receive(:create) { lookup_helper_double }
    allow(Alephant::Sequencer).to receive(:create) { sequencer_double }
  end

  describe "Status endpoint `/status`" do
    before { get "/status" }
    specify { expect(last_response.status).to eql 200 }
    specify { expect(last_response.body).to eql "ok" }
  end

  describe "404 endpoint `/banana`" do
    before { get "/banana" }
    specify { expect(last_response.status).to eql 404 }
    specify { expect(last_response.body).to eq "Not found" }
    specify { expect(last_response.headers).to include("Cache-Control") }
    specify { expect(last_response.headers).to include("Pragma") }
    specify { expect(last_response.headers).to include("Expires") }
  end

  describe "Component endpoint '/component/...' GET" do
    before do
      allow(Alephant::Storage).to receive(:new) { s3_double }
      get "/component/test_component"
    end

    context "for a valid component ID" do
      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eql "Test" }
      specify { expect(last_response.headers).to_not include("Cache-Control") }
      specify { expect(last_response.headers).to_not include("Pragma") }
      specify { expect(last_response.headers).to_not include("Expires") }
      specify { expect(last_response.headers["ETag"]).to eq("123") }
      specify { expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT") }
    end

    context "for valid URL parameters in request" do
      before { get "/component/test_component?variant=test_variant" }
      specify { expect(last_response.status).to eq 200 }
      specify { expect(last_response.body).to eq "Test" }
    end
  end

  describe "Component endpoint '/component/...' OPTIONS" do
    before do
      allow(Alephant::Storage).to receive(:new) { s3_double }
      options "/component/test_component"
    end

    context "for a valid component ID" do
      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eql "" }
      specify { expect(last_response.headers).to_not include("Cache-Control") }
      specify { expect(last_response.headers).to_not include("Pragma") }
      specify { expect(last_response.headers).to_not include("Expires") }
      specify { expect(last_response.headers["ETag"]).to eq("123") }
      specify { expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT") }
      specify { expect(last_response.headers["Content-Type"]).to eq("test/content") }
      specify { expect(last_response.headers["Content-Length"]).to eq("0") }
    end

    context "for valid URL parameters in request" do
      before { options "/component/test_component?variant=test_variant" }
      specify { expect(last_response.status).to eq 200 }
      specify { expect(last_response.body).to eq "" }
      specify { expect(last_response.headers["Content-Type"]).to eq("test/content") }
      specify { expect(last_response.headers["Content-Length"]).to eq("0") }
    end

    context "for invalid URL parameters in request" do
      before do
        content[:meta]["status"] = 404
        allow(Alephant::Storage).to receive(:new) { s3_double }
        options "/component/invalid_component"
      end
      specify { expect(last_response.status).to eq 404 }
      specify { expect(last_response.body).to eq "" }
      specify { expect(last_response.headers["Content-Type"]).to eq("test/content") }
      specify { expect(last_response.headers["Content-Length"]).to eq("0") }
    end
  end

  describe "Components endpoint '/components' POST" do
    let(:fixture_path) { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:batch_json) do
      IO.read("#{fixture_path}/batch.json").strip
    end
    let(:batch_compiled_json) do
      IO.read("#{fixture_path}/batch_compiled.json").strip
    end
    let(:s3_double_batch) { instance_double("Alephant::Storage") }

    before do
      allow(s3_double_batch).to receive(:get).and_return(
        content,
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test",
          :meta         => {
            :head_ETag            => "\"abc\"",
            :"head_Last-Modified" => "Mon, 11 Apr 2016 09:39:57 GMT"
          }
        )
      )

      allow(Alephant::Storage).to receive(:new) { s3_double_batch }
    end

    context "when using valid batch asset data" do
      let(:path) { "/components/batch" }
      let(:content_type) { "application/json" }

      before { post path, batch_json, "CONTENT_TYPE" => content_type }

      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eq batch_compiled_json }

      describe "response should have headers" do
        it "should have content headers" do
          expect(last_response.headers["Content-Type"]).to eq("application/json")
          expect(last_response.headers["Content-Length"]).to eq("306")
        end

        it "should have ETag cache header" do
          expect(last_response.headers["ETag"]).to eq('"34774567db979628363e6e865127623f"')
        end

        it "should have most recent Last-Modified header" do
          expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT")
        end
      end
    end
  end

  describe "Components endpoint '/components' GET" do
    let(:fixture_path)        { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:batch_compiled_json) do
      IO.read("#{fixture_path}/batch_compiled.json").strip
    end
    let(:s3_double_batch) { instance_double("Alephant::Storage") }

    before do
      allow(s3_double_batch).to receive(:get).and_return(
        content,
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test",
          :meta         => {
            :head_ETag            => "\"abc\"",
            :"head_Last-Modified" => "Mon, 11 Apr 2016 09:39:57 GMT"
          }
        )
      )

      allow(Alephant::Storage).to receive(:new) { s3_double_batch }
    end

    context "when using valid batch asset data" do
      let(:path)         { "/components/batch?batch_id=baz&components[ni_council_results_table][component]=ni_council_results_table&components[ni_council_results_table][options][foo]=bar&components[ni_council_results_table_no_options][component]=ni_council_results_table" }
      let(:content_type) { "application/json" }

      before { get path, {}, "CONTENT_TYPE" => content_type }

      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eq batch_compiled_json }

      describe "response should have headers" do
        it "should have content headers" do
          expect(last_response.headers["Content-Type"]).to eq("application/json")
          expect(last_response.headers["Content-Length"]).to eq("306")
        end

        it "should have ETag cache header" do
          expect(last_response.headers["ETag"]).to eq('"34774567db979628363e6e865127623f"')
        end

        it "should have most recent Last-Modified header" do
          expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT")
        end
      end
    end
  end

  describe "Components endpoint '/components' OPTIONS" do
    let(:fixture_path)        { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:s3_double_batch) { instance_double("Alephant::Storage") }

    before do
      allow(s3_double_batch).to receive(:get).and_return(
        content,
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test",
          :meta         => {
            :head_ETag            => "\"abc\"",
            :"head_Last-Modified" => "Mon, 11 Apr 2016 09:39:57 GMT"
          }
        )
      )

      allow(Alephant::Storage).to receive(:new) { s3_double_batch }
    end

    context "when using valid batch asset data" do
      let(:path)         { "/components/batch?batch_id=baz&components[ni_council_results_table][component]=ni_council_results_table&components[ni_council_results_table][options][foo]=bar&components[ni_council_results_table_no_options][component]=ni_council_results_table" }
      let(:content_type) { "application/json" }

      before { options path, {}, "CONTENT_TYPE" => content_type }

      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eq "" }

      describe "response should have headers" do
        it "should have content headers" do
          expect(last_response.headers["Content-Type"]).to eq("application/json")
          expect(last_response.headers["Content-Length"]).to eq("0")
        end

        it "should have ETag cache header" do
          expect(last_response.headers["ETag"]).to eq('"34774567db979628363e6e865127623f"')
        end

        it "should have most recent Last-Modified header" do
          expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT")
        end
      end
    end
  end

  describe "S3 headers" do
    let(:content) do
      AWS::Core::Data.new(
        :content => "missing_content",
        :meta    => {}
      )
    end
    let(:s3_double) do
      instance_double(
        "Alephant::Storage",
        :get => content
      )
    end

    context "with 404 status code set" do
      before do
        content[:meta]["status"] = 404
        allow(Alephant::Storage).to receive(:new) { s3_double }
        get "/component/test_component"
      end

      specify { expect(last_response.status).to eq 404 }
    end

    context "with cache and additional headers set" do
      before do
        content[:meta] = {
          "head_cache-control"       => "max-age=60",
          "head_x-some-header"       => "foo",
          "head_header_without_dash" => "bar",
          "status"                   => 200
        }
        allow(Alephant::Storage).to receive(:new) { s3_double }
        get "/component/test_component"
      end

      specify do
        expect(
          last_response.headers
        ).to include_case_sensitive("Cache-Control")
      end
      specify do
        expect(
          last_response.headers["Cache-Control"]
        ).to eq(content[:meta]["head_cache-control"])
      end

      specify do
        expect(
          last_response.headers
        ).to include_case_sensitive("X-Some-Header")
      end

      specify do
        expect(
          last_response.headers
        ).to include_case_sensitive("Header_without_dash")
      end

      specify { expect(last_response.headers).to_not include("Status") }
      specify { expect(last_response.status).to eq 200 }
    end
  end

  describe "Cached data" do
    let(:cache_double) do
      instance_double(
        "Alephant::Broker::Cache::Client",
        :set => {
          :content_type => "test/html",
          :content      => "<p>Some data</p>",
          :meta         => {}
        },
        :get => "<p>Some data</p>"
      )
    end
    let(:s3_double) do
      instance_double(
        "Alephant::Storage",
        :get => "test_content"
      )
    end

    context "which is old" do
      before do
        allow(Alephant::Broker::Cache::Client).to receive(:new) { cache_double }
        allow(Alephant::Storage).to receive(:new) { s3_double }
      end
      it "should update the cache (call `.set`)" do
        expect(cache_double).to receive(:set).once
      end
      after { get "/component/test_component" }
    end
  end
end
