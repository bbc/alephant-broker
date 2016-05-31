require "spec_helper"

RSpec.describe Alephant::Broker::Cache::CachedObject do
  subject { described_class.new(s3_obj) }

  let(:config)        { {} }
  let(:last_modified) { Time.parse("Mon, 11 Apr 2016 10:39:57 GMT") }
  let(:ttl)           { 15 }

  let(:s3_obj) do
    AWS::Core::Data.new(
      :content_type => "test/content",
      :content      => "Test",
      :meta         => {
        "ttl"                => ttl,
        "head_ETag"          => "123",
        "head_Last-Modified" => last_modified.to_s
      }
    )
  end

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow(Alephant::Broker).to receive(:config).and_return(config)
  end

  describe "#updated" do
    it "extracts the #updated time from the S3 object" do
      Timecop.freeze do
        expect(subject.updated).to eq(last_modified)
      end
    end

    context "when there is no Last-Modified on the S3 object" do
      let(:last_modified) { nil }

      it "sets #updated to now" do
        now = Time.parse("Mon, 31 May 2016 12:00:00 GMT")

        Timecop.freeze(now) do
          expect(subject.updated).to eq(now)
        end
      end
    end
  end

  describe "#ttl" do
    it "extracts the #ttl from the S3 object" do
      expect(subject.ttl).to eq(ttl)
    end

    context "when there is no TTL on the S3 object" do
      let(:ttl) { nil }

      context "and a default cache TTL has been configured" do
        let(:config) { { :revalidate_cache_ttl => 100 } }

        it "sets the #ttl to the configured value" do
          expect(subject.ttl).to eq(100)
        end
      end

      context "and a default cache TTL has NOT been configured" do
        it "sets the #ttl to a default (in code) value" do
          expect(subject.ttl).to eq(described_class::DEFAULT_TTL)
        end
      end
    end
  end

  describe "#update" do
    let(:new_content) do
      AWS::Core::Data.new(
        :content_type => "test/content",
        :content      => "Test - NEW",
        :meta         => {
          "ttl"                => ttl,
          "head_ETag"          => "123",
          "head_Last-Modified" => (last_modified + 100).to_s
        }
      )
    end

    it "updates #s3_obj" do
      expect { subject.update(new_content) }
        .to change { subject.s3_obj }
        .from(s3_obj)
        .to(new_content)
    end
  end

  describe "#expired?" do
    context 'when the object is "young"' do
      it "should be false" do
        Timecop.freeze(last_modified) do
          expect(subject.expired?).to be false
        end
      end
    end

    context 'when the object is "old"' do
      it "shoule be true" do
        new_time = last_modified + subject.ttl + 100

        Timecop.freeze(new_time) do
          expect(subject.expired?).to be true
        end
      end
    end
  end
end
