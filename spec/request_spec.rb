require 'spec_helper'

describe Alephant::Broker::Request do

  describe "#initialize(path, querystring)" do
    let(:component_id) { :foo }
    let(:querystring) { 'variant=test' }

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

  end
end
