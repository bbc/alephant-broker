require_relative "spec_helper"

describe Alephant::Broker::Application do
  include Rack::Test::Methods
  let(:options) do
    {
      :lookup_table_name => "test_table",
      :bucket_id         => "test_bucket",
      :path              => "bucket_path"
    }
  end

  let(:app) do
    described_class.new(
      Alephant::Broker::LoadStrategy::S3::Sequenced.new,
      options
    )
  end
  let(:content) do
    AWS::Core::Data.new(
      :content_type => "test/content",
      :content      => "Test",
      :meta         => {}
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

  let(:s3_cache_double) { instance_double("Alephant::Cache", :get => content) }

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

  describe "Component endpoint '/component/...'" do
    before do
      allow(Alephant::Cache).to receive(:new) { s3_cache_double }
      get "/component/test_component"
    end

    context "for a valid component ID" do
      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eql "Test" }
      specify { expect(last_response.headers).to_not include("Cache-Control") }
    specify { expect(last_response.headers).to_not include("Pragma") }
    specify { expect(last_response.headers).to_not include("Expires") }
    end

    context "for valid URL parameters in request" do
      before { get "/component/test_component?variant=test_variant" }
      specify { expect(last_response.status).to eq 200 }
      specify { expect(last_response.body).to eq "Test" }
    end
  end

  describe "Components endpoint '/components'" do
    let(:fixture_path) { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:batch_json) do
      IO.read("#{fixture_path}/batch.json").strip
    end
    let(:batch_compiled_json) do
      IO.read("#{fixture_path}/batch_compiled.json").strip
    end

    before do
      allow(Alephant::Cache).to receive(:new) { s3_cache_double }
    end

    context "when using valid batch asset data" do
      let(:path) { "/components/batch" }
      let(:content_type) { "application/json" }
      before { post path, batch_json, "CONTENT_TYPE" => content_type }

      specify { expect(last_response.status).to eql 200 }
      specify { expect(last_response.body).to eq batch_compiled_json }
    end
  end

  describe "S3 headers" do
    let(:content) do
      AWS::Core::Data.new(
        :content => "missing_content",
        :meta    => {}
      )
    end
    let(:s3_cache_double) do
      instance_double(
        "Alephant::Cache",
        :get => content
      )
    end

    context "with 404 status code set" do
      before do
        content[:meta]["status"] = 404
        allow(Alephant::Cache).to receive(:new) { s3_cache_double }
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
        allow(Alephant::Cache).to receive(:new) { s3_cache_double }
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
    let(:s3_cache_double) do
      instance_double(
        "Alephant::Cache",
        :get => "test_content"
      )
    end

    context "which is old" do
      before do
        allow(Alephant::Broker::Cache::Client).to receive(:new) { cache_double }
        allow(Alephant::Cache).to receive(:new) { s3_cache_double }
      end
      it "should update the cache (call `.set`)" do
        expect(cache_double).to receive(:set).once
      end
      after { get "/component/test_component" }
    end
  end
end
