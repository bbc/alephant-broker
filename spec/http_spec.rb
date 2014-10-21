require "spec_helper"

describe Alephant::Broker::LoadStrategy::HTTP do
  subject { described_class.new(url_strategy) }

  let(:component_meta) do
    double('Alephant::Broker::ComponentMeta', cache_key: "cache_key")
  end
  let(:url_strategy) { double(generate: "http://foo.bar") }
  let(:cache) { double('Alephant::Broker::Cache::Client') }
  let(:body) { "body" }

  before :each do
    allow(Alephant::Broker::Cache::Client).to receive(:new) { cache }
  end

  describe "#load" do
    context "content in cache" do
      it "gets from cache" do
        allow(cache).to receive(:get) { body }

        expect(subject.load component_meta).to eq body
      end
    end

    context "content not in cache" do
      it "gets from HTTP" do
        allow(component_meta).to receive(:'cached=').with(false) { false }
        allow(component_meta).to receive(:options).and_return("somethingTODO")
        allow(Faraday).to receive(:get) do
          double('Faraday', body: body, :'success?' => true)
        end
        allow(cache).to receive(:get).and_yield

        expect(subject.load component_meta).to eq body
      end
    end
  end
end
