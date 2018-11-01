require 'spec_helper'

RSpec.describe Alephant::Broker::Cache::Client do
  before do
    allow(Alephant::Broker).to receive(:config).and_return(config)
  end

  context 'when creating a new cache client with no cache endpoint' do
    let(:config) { {} }

    it 'creates a cache client with a null client backend' do
      expect(Alephant::Broker::Cache::NullClient).to receive(:new)
      expect(Dalli::Client).not_to receive(:new)

      expect(described_class.new).to be_a described_class
    end
  end

  context 'when creating a new cache client with a cache endpoint' do
    let(:config) { { elasticache_config_endpoint: 'abc123.elasticache.aws.com:11211' } }

    it 'creates a cache client with a null client backend' do
      expect(Alephant::Broker::Cache::NullClient).not_to receive(:new)
      expect(Dalli::Client).to receive(:new)

      expect(described_class.new).to be_a described_class
    end
  end
end