ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require 'rack/test'
require 'alephant/broker'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe 'Broker Rack Application' do
  before do
    allow_any_instance_of(Alephant::Broker::Component).to receive(:load)
      .and_return('Test')

    allow_any_instance_of(Alephant::Broker::Component).to receive(:content)
      .and_return('Test')

    allow_any_instance_of(Alephant::Broker::Component).to receive(:content_type)
      .and_return('foo/bar')

    allow_any_instance_of(Alephant::Broker::Component).to receive(:version)
      .and_return(1)

    allow_any_instance_of(Alephant::Broker::Response::Asset).to receive(:status)
      .and_return(200)
  end

  def app
    Alephant::Broker::Application.new({
      :lookup_table_name  => 'test_table',
      :bucket_id          => 'test_bucket',
      :path               => 'bucket_path'
    })
  end

  it 'Tests status page' do
    get '/status'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('ok')
  end

  it "Tests not found page" do
    get '/some/non-existent-page'
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq('Not found')
  end

  it "Test asset data is returned" do
    get '/component/test_component'

    expect(last_response).to be_ok
    expect(last_response.body).to eq('Test')
  end

  it "Tests query string parameters are passed correctly to lookup" do
    get '/component/test_component?variant=test_variant'

    expect(last_response).to be_ok
    expect(last_response.body).to eq('Test')
  end

  it "Tests 404 when lookup doesn't return a valid location" do
    allow_any_instance_of(Alephant::Broker::Response::Asset).to receive(:status)
      .and_return(404)

    get '/component/test_component'

    expect(last_response.status).to eq(404)
  end

  it "Tests 500 when exception is raised in application" do
    allow_any_instance_of(Alephant::Broker::Response::Asset).to receive(:status)
      .and_return(500)

    get '/component/test_component'

    expect(last_response.status).to eq(500)
  end

  it "Test batch asset data is returned" do
    json          = '{"batch_id":"baz","components":[{"component":"ni_council_results_table"},{"component":"ni_council_results_table"}]}'
    compiled_json = '{"batch_id":"baz","components":[{"component":"ni_council_results_table","options":{},"status":200,"content_type":"foo/bar","body":"Test"},{"component":"ni_council_results_table","options":{},"status":200,"content_type":"foo/bar","body":"Test"}]}'

    post '/components/batch', json, "CONTENT_TYPE" => "application/json"

    expect(last_response).to be_ok
    expect(last_response.body).to eq(compiled_json)
  end
end
