require 'spec_helper'

describe Alephant::Broker::Application do
  include Rack::Test::Methods

  let(:app) do
    described_class.new(
      Alephant::Broker::LoadStrategy::S3,
      {
        :lookup_table_name => 'test_table',
        :bucket_id         => 'test_bucket',
        :path              => 'bucket_path'
      }
    )
  end
  let(:cache_hash) do
    {
      :content_type => 'test/content',
      :content      => 'Test'
    }
  end
  let(:sequencer_double) do
    instance_double(
      'Alephant::Sequencer::Sequencer',
      :get_last_seen => '111'
    )
  end

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)

    allow_any_instance_of(Alephant::Broker::Cache::Client)
      .to receive(:get).and_return(cache_hash)

    allow_any_instance_of(Alephant::Broker::Component)
      .to receive_messages(
        :content      => cache_hash[:content],
        :content_type => 'foo/bar',
        :version      => 1
      )

    allow_any_instance_of(Alephant::Broker::Response::Asset)
      .to receive(:status).and_return(200)

    allow(Alephant::Sequencer).to receive(:create) { sequencer_double }
  end

  describe 'Status endpoint `/status`' do
    before { get '/status' }
    specify { expect(last_response.status).to eql 200 }
    specify { expect(last_response.body).to eql 'ok' }
  end

  describe '404 endpoint `/banana`' do 
    before { get '/banana' }
    specify { expect(last_response.status).to eql 404 }
    specify { expect(last_response.body).to eq 'Not found' }
  end

  describe 'Component endpoint `/component/...`' do
    let(:batch_json) do
      IO.read("#{File.dirname(__FILE__)}/fixtures/json/batch.json").strip
    end
    let(:batch_compiled_json) do
      IO.read("#{File.dirname(__FILE__)}/fixtures/json/batch_compiled.json").strip
    end

    context 'status code' do
      context 'for a valid component ID' do
        before { get '/component/test_component' }      
        specify { expect(last_response.status).to eql 200 }
      end

      context 'for valid URL parameters in request' do
        before { get '/component/test_component?variant=test_variant' }
        specify { expect(last_response.status).to eq 200 }
      end

      context 'when using valid batch asset data' do
        before { post '/components/batch', batch_json, 'CONTENT_TYPE' => 'application/json' }
        specify { expect(last_response.status).to eql 200 }
      end
    end

    context 'response body' do
      context 'for a valid component ID' do
        before { get '/component/test_component' }      
        specify { expect(last_response.body).to eql 'Test' }
      end

      context 'for valid URL parameters in request' do
        before { get '/component/test_component?variant=test_variant' }
        specify { expect(last_response.body).to eq 'Test' }
      end
   
      context 'when using valid batch asset data' do
        before { post '/components/batch', batch_json, 'CONTENT_TYPE' => 'application/json' }
        specify { expect(last_response.body).to eql batch_compiled_json }
      end
    end
  end

  describe 'Cached data' do
    let(:cache_double) do
      instance_double(
        'Alephant::Broker::Cache::Client',
        :set => { 
          :content_type => 'test/html',
          :content => '<p>Some data</p>' 
        }, 
        :get => '<p>Some data</p>'
      )
    end
    let(:lookup_location_double) do
      instance_double('Alephant::Lookup::Location', location: 'test/location')
    end
    let(:lookup_helper_double) do
      instance_double('Alephant::Lookup::LookupHelper', read: lookup_location_double)
    end
    let(:s3_cache_double) do
      instance_double(
        'Alephant::Cache',
        :get => 'test_content'
      )
    end

    context 'which is old' do
      before do
        allow(Alephant::Lookup).to receive(:create) { lookup_helper_double }
        allow(Alephant::Broker::Cache::Client).to receive(:new) { cache_double }
        allow(Alephant::Cache).to receive(:new) { s3_cache_double }
      end
      it 'should update the cache (call `.set`)' do
        expect(cache_double).to receive(:set).once
      end 
      after { get '/component/test_component' }
    end
  end
end
