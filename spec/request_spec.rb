require 'spec_helper'

describe Alephant::Broker::Request do

  describe "#initialize(path, querystring)" do
    let(:component_id) { 'foo' }
    let(:querystring) { 'variant=test' }


    it "Sets the component id" do

      instance = Alephant::Broker::Request.new("/component/#{component_id}", '')
      expect(instance.component_id).to eq(component_id)
    end

    it "Sets the request type to asset" do

      instance = Alephant::Broker::Request.new("/component/#{component_id}", '')
      expect(instance.type).to eq(:asset)
      expect(instance.options).to eq({})
    end

    it "Sets the request type to asset with parsed options" do
      instance = Alephant::Broker::Request.new("/component/#{component_id}", querystring)
      expect(instance.type).to eq(:asset)
      expect(instance.options).to eq({ :variant => 'test' })

    end

    it "Sets the request type to status" do
      instance = Alephant::Broker::Request.new("/status", '')
      expect(instance.type).to eq(:status)
    end

    it "Sets the default extension" do
      instance = Alephant::Broker::Request.new("/component/blah", '')
      expect(instance.extension).to eq(:html)
    end

    it "Sets the extension from the path" do
      instance = Alephant::Broker::Request.new("/component/blah.json", '')
      expect(instance.extension).to eq(:json)
    end

    it "Sets the content type to default if the extension does not exist" do
      instance = Alephant::Broker::Request.new("/component/blah.test", '')
      expect(instance.content_type).to eq('text/html')
    end

  end
end
