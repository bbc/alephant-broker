require 'spec_helper'

describe Alephant::Broker::AssetResponse do

  describe "#initialize(request, config)" do
    let(:config) { { :lookup_table_name => 'test_table', :bucket_id => 'test_bucket', :path => 'test_path' } }
    let(:request) { double("Alephant::Broker::Request", :component_id => 'test', :content_type => 'text/html', :options => {:variant => 'test_variant'} ) }
    let(:location) { 'test_location' }

    before {
      @lookup_table = double('Alephant::Lookup::LookupTable')
      Alephant::Lookup.stub(:create).and_return(@lookup_table)
    }

    it "Should return the content from a successful cache lookup" do
      allow(@lookup_table).to receive(:read).with(request.options).and_return(location)
      Alephant::Cache.any_instance.stub(:initialize)
      Alephant::Cache.any_instance.stub(:get).with(location).and_return('Test cache content')
      instance = Alephant::Broker::AssetResponse.new(request, config)

      expect(instance.content).to eq('Test cache content')
      expect(instance.status).to eq(200)
    end

    it "should return a 404 if lookup can't find a valid location" do
      allow(@lookup_table).to receive(:read).with(request.options).and_return(nil)
      Alephant::Cache.any_instance.stub(:initialize)
      instance = Alephant::Broker::AssetResponse.new(request, config)

      expect(instance.content).to eq('Cache key not found based on component_id and options combination')
      expect(instance.status).to eq(404)
    end

    it "should return a 500 for any other exceptions" do
      allow(@lookup_table).to receive(:read).with(request.options).and_raise(Exception)
      instance = Alephant::Broker::AssetResponse.new(request, config)

      expect(instance.status).to eq(500)

    end

  end

end


