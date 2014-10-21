require "spec_helper"

describe Alephant::Broker::LoadStrategy::HTTP do
  subject { described_class.new(url_generator) }

  let(:component_meta) do
    double('Alephant::Broker::ComponentMeta', cache_key: "cache_key")
  end
  let(:url_generator) { double(generate: "http://foo.bar") }
  let(:cache) { double('Alephant::Broker::Cache::Client') }
  let(:body) { "body" }

  before :each do
    allow(Alephant::Broker::Cache::Client).to receive(:new) { cache }
  end

  describe "#load" do
    context "content in cache" do
      before :each do
        allow(cache).to receive(:get) { body }
      end

      it "gets from cache" do
        expect(subject.load component_meta).to eq body
      end
    end

    context "content not in cache" do
      before :each do
        allow(cache).to receive(:get).and_yield
        allow(component_meta).to receive(:'cached=').with(false) { false }
        allow(component_meta).to receive(:options).and_return Hash.new
      end

      context "and available over HTTP" do
        it "gets from HTTP" do
          allow(Faraday).to receive(:get) do
            double('Faraday', body: body, :'success?' => true)
          end

          expect(subject.load component_meta).to eq body
        end
      end

      context "and HTTP request fails" do
        specify do
          allow(Faraday).to receive(:get).and_raise 

          expect do
            subject.load component_meta
          end.to raise_error Alephant::Broker::LoadStrategy::HTTP::RequestFailed
        end
      end

      context "and HTTP request 404s" do
        specify do
          allow(Faraday).to receive(:get) do
            double('Faraday', body: body, :'success?' => false)
          end

          expect do
            subject.load component_meta
          end.to raise_error Alephant::Broker::LoadStrategy::HTTP::RequestFailed
        end
      end
    end
  end
end
