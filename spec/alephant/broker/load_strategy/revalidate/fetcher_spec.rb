require "spec_helper"

RSpec.describe Alephant::Broker::LoadStrategy::Revalidate::Fetcher do
  subject { described_class.new(component_meta) }

  let(:component_meta) do
    Alephant::Broker::ComponentMeta.new("test", "test_batch", {})
  end

  let(:lookup_double)  { instance_double(Alephant::Lookup::LookupHelper) }
  let(:storage_double) { instance_double(Alephant::Storage) }

  before do
    allow(Alephant::Lookup).to receive(:create).and_return(lookup_double)
    allow(Alephant::Storage).to receive(:new).and_return(storage_double)
    allow(Alephant::Broker).to receive(:config).and_return({})
    allow_any_instance_of(Logger).to receive(:info)
  end

  describe "#fetch" do
    context "when there is something in DynamoDB & S3" do
      let(:content_body) { "<h1>w00t</h1>" }
      let(:content_type) { "text/html" }

      let(:content) do
        instance_double(AWS::S3::S3Object,
          :content_type => "test/content",
          :read         => "Test",
          :metadata     => {
            "ttl"                => 30,
            "head_ETag"          => "123",
            "head_Last-Modified" => "Mon, 11 Apr 2016 10:39:57 GMT"
          }
        )
      end

      before do
        allow(lookup_double)
          .to receive(:read)
          .and_return(spy(:location => "/foo/bar"))

        allow(storage_double)
          .to receive(:get)
          .with("/foo/bar")
          .and_return(content)
      end

      it "fetches and returns the content as a CachedObject" do
        returned_data = subject.fetch
        expect(returned_data.s3_obj).to eq(content)
      end
    end

    context "when there is NO entry in DynamoDB" do
      before do
        allow(lookup_double)
          .to receive(:read)
          .and_return(spy(:location => nil))
      end

      it "raises an Alephant::Broker::Errors::ContentNotFound error" do
        expect { subject.fetch }
          .to raise_error(Alephant::Broker::Errors::ContentNotFound)
      end
    end

    context "when there is an entry in DynamoDB" do
      before do
        allow(lookup_double)
          .to receive(:read)
          .and_return(spy(:location => "/foo/bar"))
      end

      context "but there is NO content in S3" do
        before do
          allow(storage_double)
            .to receive(:get)
            .and_raise(AWS::S3::Errors::NoSuchKey.new(nil, nil))
        end

        it "raises an Alephant::Broker::Errors::ContentNotFound error" do
          expect { subject.fetch }
            .to raise_error(Alephant::Broker::Errors::ContentNotFound)
        end
      end
    end
  end
end
