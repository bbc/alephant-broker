require "spec_helper"

describe Alephant::Broker::LoadStrategy::HTTP do
  subject { described_class.new(url_generator) }

  let(:component_meta) do
    double(
      'Alephant::Broker::ComponentMeta',
      cache_key: 'cache_key',
      id: 'test',
      options: {}
    )
  end
  let(:url_generator) { double(generate: "http://foo.bar") }
  let(:cache) { double('Alephant::Broker::Cache::Client') }
  let(:body) { '<h1>Batman!</h1>' }
  let(:content) do
    {
      :content => body,
      :content_type => 'text/html'
    }
  end

  before :each do
    allow(Alephant::Broker::Cache::Factory).to receive(:create) { cache }
  end

  describe "#load" do
    context "content in cache" do
      before :each do
        allow(cache).to receive(:get) { content }
      end

      it "gets from cache" do
        expect(subject.load component_meta).to eq content
      end
    end

    context "content not in cache" do
      before :each do
        allow(cache).to receive(:get).and_yield
        allow(component_meta).to receive(:'cached=').with(false) { false }
      end

      context "and available over HTTP" do
        let(:env) { double('env', response_headers: response_headers) }
        let(:response_headers) { {'content-type' => 'text/html; test'} }

        before :each do
          allow(Faraday).to receive(:get) do
            instance_double(
              'Faraday::Response',
              body: body,
              :'success?' => true,
              env: env)
          end
         end

        it "gets from HTTP" do
         expect(subject.load component_meta).to eq content
        end
      end

      context "and HTTP request fails" do
        before :each do
          allow(Faraday).to receive(:get).and_raise
        end

        specify do
          expect do
            subject.load component_meta
          end.to raise_error
        end
      end

      context "and HTTP request 404s" do
        before :each do
          allow(Faraday).to receive(:get) do
            instance_double('Faraday::Response', body: body, :'success?' => false)
          end
        end

        specify do
          expect do
            subject.load component_meta
          end.to raise_error
        end
      end
    end
  end
end
