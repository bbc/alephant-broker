ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'alephant/broker/app/rack'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe 'Broker rack app tests' do

  before {
    @lookup_table = double('Alephant::Lookup::LookupTable')
    Alephant::Lookup.stub(:create).and_return(@lookup_table)

    Alephant::Cache.any_instance.stub(:initialize)
    Alephant::Cache.any_instance.stub(:get).and_return('Test response')
  }

  def app
    Alephant::Broker::RackApplication.new({
      :lookup_table_name  => 'test_table',
      :bucket_id          => 'test_bucket',
      :path               => 'bucket_path'
    })
  end

  it "Tests status page" do
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
    allow(@lookup_table).to receive(:read).and_return('some_location')

    get '/component/test_component'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Test response')
  end

  it "Tests query string parameters are passed correctly to lookup" do
    variant = {:variant => 'test_variant'}
    allow(@lookup_table).to receive(:read).with(variant).and_return('some_location')

    get '/component/test_component?variant=test_variant'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('Test response')
  end

  it "Tests 404 when lookup doesn't return a valid location" do
    allow(@lookup_table).to receive(:read).and_return(nil)

    get '/component/test_component'
    expect(last_response.status).to eq(404)

  end

  it "Tests 500 when exception is raised in application" do
    allow(@lookup_table).to receive(:read).and_raise(Exception)

    get '/component/test_component'
    expect(last_response.status).to eq(500)
  end

end
