require_relative "spec_helper"

describe Alephant::Broker::Application do
  include Rack::Test::Methods

  let(:config) do
    {
      :aws_account_id    => "12345",
      :lookup_table_name => "test_table",
      :s3_bucket_id      => "test_bucket",
      :s3_object_path    => "bucket_path",
      :sqs_queue_name    => "test_queue"
    }
  end

  let(:app) do
    described_class.new(
      Alephant::Broker::LoadStrategy::Revalidate::Strategy.new,
      config
    )
  end

  let(:content) do
    instance_double(AWS::S3::S3Object,
      :content_type => "test/content",
      :read         => "Test",
      :metadata     => {
        "ttl"                => "35",
        "head_ETag"          => "123",
        "head_Last-Modified" => "Mon, 11 Apr 2016 10:39:57 GMT"
      }
    )
  end

  let(:lookup_location_double) { instance_double(Alephant::Lookup::LookupLocation, :location => "test/location") }
  let(:lookup_helper_double)   { instance_double(Alephant::Lookup::LookupHelper, :read => lookup_location_double) }
  let(:storage_double)         { instance_double(Alephant::Storage, :get => content) }
  let(:sqs_double)             { instance_double(AWS::SQS, :queues => sqs_queues_double) }
  let(:sqs_queue_double)       { instance_double(AWS::SQS::Queue, :send_message => nil) }
  let(:sqs_queues_double)      { instance_double(AWS::SQS::QueueCollection, :url_for => "example.com", :[] => sqs_queue_double) }

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)
    allow(Thread).to receive(:new).and_yield
    allow(Alephant::Lookup).to receive(:create).and_return(lookup_helper_double)
    allow(Alephant::Storage).to receive(:new).and_return(storage_double)
    allow(AWS::SQS).to receive(:new).and_return(sqs_double)
  end

  describe "GET `/status`" do
    before { get("/status") }
    specify { expect(last_response.status).to eql(200) }
    specify { expect(last_response.body).to eql("ok") }
  end

  describe "GET an undefined endpoint" do
    before { get("/wotever") }
    specify { expect(last_response.status).to eql(404) }
    specify { expect(last_response.body).to eq("Not found") }
    specify { expect(last_response.headers).to include("Cache-Control") }
    specify { expect(last_response.headers).to include("Pragma") }
    specify { expect(last_response.headers).to include("Expires") }
  end

  describe "GET `/component/....`" do
    context "when the content IS available from S3/storage" do
      before { get("/component/test_component") }

      specify { expect(last_response.status).to eql(200) }
      specify { expect(last_response.body).to eql("Test") }
      specify { expect(last_response.headers).to_not include("Cache-Control") }
      specify { expect(last_response.headers).to_not include("Pragma") }
      specify { expect(last_response.headers).to_not include("Expires") }
      specify { expect(last_response.headers["ETag"]).to eq("123") }
      specify { expect(last_response.headers["Last-Modified"]).to eq("Mon, 11 Apr 2016 10:39:57 GMT") }
      specify { expect(last_response.headers["Content-Type"]).to eq("test/content") }
      specify { expect(last_response.headers["Content-Length"]).to eq("4") }
    end

    context "when the content IS NOT available from S3/storage" do
      before do
        expect(storage_double)
          .to receive(:get)
          .and_raise(AWS::S3::Errors::NoSuchKey.new(nil, nil))

        get("/component/test_component")
      end

      specify { expect(last_response.status).to eql(202) }
      specify { expect(last_response.body).to eql("Accepted") }
    end
  end

  describe "`/components`" do
    let(:fixture_path) { "#{File.dirname(__FILE__)}/../fixtures/json" }
    let(:batch_json) { IO.read("#{fixture_path}/batch.json").strip }
    let(:batch_compiled_json) { IO.read("#{fixture_path}/batch_compiled.json").strip }

    before do
      allow(storage_double)
        .to receive(:get)
        .and_return(
          content,
          instance_double(AWS::S3::S3Object,
            :content_type => "test/content",
            :read         => "Test",
            :metadata     => {
              "head_ETag"          => "\"abc\"",
              "head_Last-Modified" => "Mon, 11 Apr 2016 09:39:57 GMT"
            }
          )
      )
    end

    describe "POST" do
      let(:path) { "/components/batch" }
      let(:content_type) { "application/json" }

      context "when the content is available from S3/Storage" do
        before { post(path, batch_json, "CONTENT_TYPE" => content_type) }

        specify { expect(last_response.status).to eql(200) }
        specify { expect(last_response.body).to eq(batch_compiled_json) }
      end

      context "when the content IS NOT available from S3/storage" do
        before do
          allow(storage_double)
            .to receive(:get)
            .and_raise(AWS::S3::Errors::NoSuchKey.new(nil, nil))

          post(path, batch_json, "CONTENT_TYPE" => content_type)
        end

        specify { expect(last_response.status).to eql(200) }

        specify do
          statuses = JSON.parse(last_response.body)["components"].map { |c| c["status"] }
          expect(statuses).to eq([202, 202])
        end
      end
    end

    describe "GET" do
      let(:path)         { "/components/batch?batch_id=baz&components[ni_council_results_table][component]=ni_council_results_table&components[ni_council_results_table][options][foo]=bar&components[ni_council_results_table_no_options][component]=ni_council_results_table" }
      let(:content_type) { "application/json" }

      context "when the content is available from S3/Storage" do
        before { get(path, {}, "CONTENT_TYPE" => content_type) }

        specify { expect(last_response.status).to eql(200) }
        specify { expect(last_response.body).to eq(batch_compiled_json) }
      end

      context "when the content IS NOT available from S3/storage" do
        before do
          allow(storage_double)
            .to receive(:get)
            .and_raise(AWS::S3::Errors::NoSuchKey.new(nil, nil))

          get(path, {}, "CONTENT_TYPE" => content_type)
        end

        specify { expect(last_response.status).to eql(200) }

        specify do
          statuses = JSON.parse(last_response.body)["components"].map { |c| c["status"] }
          expect(statuses).to eq([202, 202])
        end
      end
    end
  end
end
