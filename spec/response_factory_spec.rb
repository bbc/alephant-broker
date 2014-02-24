require 'spec_helper'

describe Alephant::Broker::ResponseFactory do

  describe "#response_from(request)" do
    let (:request) { double("Alephant::Broker::Request") }

    it "should return as asset response" do
      instance = Alephant::Broker::ResponseFactory.new({})
      allow(request).to receive(:type).and_return(:asset)

      Alephant::Broker::AssetResponse.any_instance.stub(:initialize).with(request, {})
      expect(instance.response_from(request)).to be_a Alephant::Broker::AssetResponse
    end

    it "should return a status response" do
      allow(request).to receive(:type).and_return(:status)
      response = subject.response_from(request)
      expect(response.status).to eq(200)
    end

    it "should return a 404 response" do
      allow(request).to receive(:type).and_return(:notfound)
      response = subject.response_from(request)
      expect(response.status).to eq(404)
    end

    it "should return a 500 response" do
      allow(request).to receive(:type).and_return(:error)
      response = subject.response_from(request)
      expect(response.status).to eq(500)
    end

  end
end
