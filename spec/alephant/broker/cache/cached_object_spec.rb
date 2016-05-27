require "spec_helper"

RSpec.describe Alephant::Broker::Cache::CachedObject do
  subject { described_class.new(s3_obj) }

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
  end

  describe "#initialize" do
    it "populates #s3_obj" do
      expect(subject.s3_obj).to eq(s3_obj)
    end

    it "extracts the #updated time" do
      Timecop.freeze do
        expect(subject.updated).to eq(last_modified)
      end
    end

    context "there is no TTL on the S3 object" do
      let(:s3_obj) do
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test",
          :meta         => {}
        )
      end

      it "sets the #ttl to a default value" do
        expect(subject.ttl).to eq(described_class::DEFAULT_TTL)
      end
    end

    context "there is no Last-Modified on the S3 object" do
      let(:s3_obj) do
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test",
          :meta         => {}
        )
      end

      it "sets #updated to now" do
        Timecop.freeze(last_modified) do
          expect(subject.updated).to eq(last_modified)
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

    it "reloads the #updated time" do
      expect { subject.update(new_content) }
        .to change { subject.updated }
        .from(last_modified)
        .to(last_modified + 100)
    end

    context "there is no TTL on the S3 object" do
      let(:new_content) do
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test - NEW",
          :meta         => {}
        )
      end

      it "sets the #ttl to a default value" do
        expect { subject.update(new_content) }
          .to change { subject.ttl }
          .from(ttl)
          .to(described_class::DEFAULT_TTL)
      end
    end

    context "there is no Last-Modified on the S3 object" do
      let(:new_content) do
        AWS::Core::Data.new(
          :content_type => "test/content",
          :content      => "Test - NEW",
          :meta         => {}
        )
      end

      it "sets #updated to now" do
        new_time = Time.parse("Mon, 27 Apr 2016 10:39:57 GMT")

        Timecop.freeze(new_time) do
          expect { subject.update(new_content) }
            .to change { subject.updated }
            .from(last_modified)
            .to(new_time)
        end
      end
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
