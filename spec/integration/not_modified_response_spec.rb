require_relative "spec_helper"
require "alephant/broker"

describe Alephant::Broker::Application do
  include Rack::Test::Methods

  let(:options) do
    {
      :lookup_table_name                  => "test_table",
      :bucket_id                          => "test_bucket",
      :path                               => "bucket_path",
      :allow_not_modified_response_status => true
    }
  end

  let(:app) do
    described_class.new(
      Alephant::Broker::LoadStrategy::S3::Sequenced.new,
      options
    )
  end

  let(:content) do
    {
      :content_type => "test/content",
      :content      => "Test",
      :meta         => {
        "head_ETag"          => "123",
        "head_Last-Modified" => "Mon, 11 Apr 2016 10:39:57 GMT"
      }
    }
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

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)
    allow(Alephant::Lookup).to receive(:create) { lookup_helper_double }
    allow(Alephant::Sequencer).to receive(:create) { sequencer_double }
  end

  describe "single component not modified response" do
    before do
      allow(Alephant::Storage).to receive(:new) { s3_double }
      get(
        "/component/test_component",
        {},
        "HTTP_IF_MODIFIED_SINCE" => "Mon, 11 Apr 2016 10:39:57 GMT"
      )
    end

    specify { expect(last_response.status).to eql(304) }
    specify { expect(last_response.body).to eql("") }
    specify { expect(last_response.headers).to_not include("Cache-Control") }
    specify { expect(last_response.headers).to_not include("Pragma") }
    specify { expect(last_response.headers).to_not include("Expires") }
    specify { expect(last_response.headers["ETag"]).to eq("123") }
    specify { expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT") }
  end

  describe "Components POST unmodified '/components' response" do
    let(:fixture_path)        { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:batch_json)          { IO.read("#{fixture_path}/batch.json").strip }
    let(:batch_compiled_json) { IO.read("#{fixture_path}/batch_compiled.json").strip }
    let(:s3_double_with_etag) { instance_double("Alephant::Storage") }
    let(:lookup_location_double_for_options_request) do
      instance_double("Alephant::Lookup::Location", :location => "test/location/with/options")
    end

    before do
      allow(lookup_helper_double).to receive(:read)
        .with("ni_council_results_table", { :foo => "bar" }, "111")
        .and_return(lookup_location_double_for_options_request)

      allow(s3_double_with_etag).to receive(:get)
        .with("test/location")
        .and_return(
          content
        )

      allow(s3_double_with_etag).to receive(:get)
        .with("test/location/with/options")
        .and_return(
          {
            :content_type => "test/content",
            :content      => "Test",
            :meta         => {
              "head_ETag"          => "abc",
              "head_Last-Modified" => "Mon, 11 Apr 2016 09:39:57 GMT"
            }
          }
        )

      allow(Alephant::Storage).to receive(:new) { s3_double_with_etag }
    end

    context "when requesting an unmodified response" do
      let(:path)         { "/components/batch" }
      let(:content_type) { "application/json" }
      let(:etag)         { '"34774567db979628363e6e865127623f"' }

      before do
        post(path, batch_json,
          "CONTENT_TYPE"       => content_type,
          "HTTP_IF_NONE_MATCH" => etag)
      end

      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eq batch_compiled_json }

      describe "response should have headers" do
        it "should have a Content-Type header" do
          expect(last_response.headers).to include("Content-Type")
        end

        it "should have ETag cache header" do
          expect(last_response.headers["ETag"]).to eq(etag)
        end

        it "should have most recent Last-Modified header" do
          expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT")
        end

        it "shoud not have no cache headers" do
          expect(last_response.headers).to_not include("Cache-Control")
          expect(last_response.headers).to_not include("Pragma")
          expect(last_response.headers).to_not include("Expires")
        end
      end
    end
  end

  describe "Components GET unmodified '/components' response" do
    let(:fixture_path)        { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:batch_compiled_json) { IO.read("#{fixture_path}/batch_compiled.json").strip }
    let(:s3_double_with_etag) { instance_double("Alephant::Storage") }
    let(:lookup_location_double_for_options_request) do
      instance_double("Alephant::Lookup::Location", :location => "test/location/with/options")
    end

    before do
      allow(lookup_helper_double).to receive(:read)
        .with("ni_council_results_table", { :foo => "bar" }, "111")
        .and_return(lookup_location_double_for_options_request)

      allow(s3_double_with_etag).to receive(:get)
        .with("test/location")
        .and_return(
          content
        )

      allow(s3_double_with_etag).to receive(:get)
        .with("test/location/with/options")
        .and_return(
          {
            :content_type => "test/content",
            :content      => "Test",
            :meta         => {
              "head_ETag"          => "abc",
              "head_Last-Modified" => "Mon, 11 Apr 2016 09:39:57 GMT"
            }
          }
        )

      allow(Alephant::Storage).to receive(:new) { s3_double_with_etag }
    end

    context "when requesting an unmodified response with GET" do
      let(:path)         { "/components/batch?batch_id=baz&components[ni_council_results_table][component]=ni_council_results_table&components[ni_council_results_table][options][foo]=bar&components[ni_council_results_table_no_options][component]=ni_council_results_table" }
      let(:content_type) { "application/json" }
      let(:etag)         { '"34774567db979628363e6e865127623f"' }

      before do
        get(
          path,
          {},
          "CONTENT_TYPE"       => content_type,
          "HTTP_IF_NONE_MATCH" => etag
        )
      end

      specify { expect(last_response.status).to eql(304) }
      specify { expect(last_response.body).to eq("") }

      describe "response should have headers" do
        it "should not have a Content-Type header" do
          expect(last_response.headers).to_not include("Content-Type")
        end

        it "should have ETag cache header" do
          expect(last_response.headers["ETag"]).to eq(etag)
        end

        it "should have most recent Last-Modified header" do
          expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT")
        end

        it "shoud not have no cache headers" do
          expect(last_response.headers).to_not include("Cache-Control")
          expect(last_response.headers).to_not include("Pragma")
          expect(last_response.headers).to_not include("Expires")
        end
      end
    end
  end
end
