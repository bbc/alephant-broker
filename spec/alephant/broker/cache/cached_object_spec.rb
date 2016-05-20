require "spec_helper"

RSpec.describe Alephant::Broker::Cache::CachedObject do
  subject { described_class.new(content, content_type) }

  let(:content)      { double(:content) }
  let(:content_type) { "text/plain" }

  before do
    allow_any_instance_of(described_class).to receive(:logger).and_return(spy)
  end

  describe "#initialize" do
    it "populates #content" do
      expect(subject.content).to eq(content)
    end

    it "populates #content_type" do
      expect(subject.content_type).to eq(content_type)
    end

    it "sets the #updated time to now" do
      Timecop.freeze do
        expect(subject.updated).to eq(Time.now)
      end
    end

    it "sets #validating as false" do
      expect(subject.validating).to be false
    end
  end

  describe "#update" do
    let(:new_content) do
      {
        :content      => "{}",
        :content_type => "application/json"
      }
    end

    it "updates #content" do
      expect { subject.update(new_content) }
        .to change { subject.content }
        .from(content)
        .to(new_content[:content])
    end

    it "updates #content_type" do
      expect { subject.update(new_content) }
        .to change { subject.content_type }
        .from(content_type)
        .to(new_content[:content_type])
    end

    it "resets the #updated time to now" do
      original_time = subject.updated.dup
      new_time      = original_time + 100

      Timecop.freeze(new_time) do
        expect { subject.update(new_content) }
          .to change { subject.updated }
          .from(original_time)
          .to(new_time)
      end
    end

    it "resets #validating as false" do
      subject.now_validating

      expect { subject.update(new_content) }
        .to change { subject.validating }
        .from(true)
        .to(false)
    end
  end

  describe "#now_validating" do
    it "sets #validating as true" do
      expect { subject.now_validating }
        .to change { subject.validating }
        .from(false)
        .to(true)
    end

    it "sets #last_validate as now" do
      Timecop.freeze do
        expect { subject.now_validating }
          .to change { subject.last_validate }
          .from(nil)
          .to(Time.now)
      end
    end
  end

  describe "#validating?" do
    context "when the object has NOT been told to validate" do
      it "should be false" do
        expect(subject.validating?).to be false
      end
    end

    context "when the object has been told to validate" do
      context 'and the object is "young" enough' do
        it "should be true" do
          Timecop.freeze do
            subject.now_validating
            expect(subject.validating?).to be true
          end
        end
      end

      context 'and the object has "expired"' do
        it "should be false" do
          subject.now_validating
          new_time = Time.now + described_class::VALIDIATE_TIMEOUT + 100

          Timecop.freeze(new_time) do
            expect(subject.validating?).to be false
          end
        end
      end
    end
  end

  describe "#expired?" do
    context 'when the object is "young"' do
      it "should be false" do
        expect(subject.expired?).to be false
      end
    end

    context 'when the object is "old"' do
      it "shoule be true" do
        new_time = Time.now + subject.ttl + 100

        Timecop.freeze(new_time) do
          expect(subject.expired?).to be true
        end
      end
    end
  end
end
