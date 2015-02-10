require "spec_helper"

describe Alephant::Broker::LoadStrategy::S3::Archived do
  subject { described_class.new }

  describe "#s3_path" do
    let(:id) { 42 }
    let(:component_meta) { double(:id => id) }

    specify do
      expect(subject.s3_path component_meta).to eq id
    end

    context "no location associated with component meta" do
      let(:component_meta) { double(:id => nil) }

      specify do
        expect do
          subject.s3_path component_meta
        end.to raise_error Alephant::Broker::InvalidCacheKey
      end
    end
  end
end
