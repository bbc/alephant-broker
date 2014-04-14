require 'spec_helper'

describe Alephant::Broker::ResponseFactory do
  describe "#response_from(request)" do
    let (:request) { double("Alephant::Broker::Request") }
    let (:post_request) { double("Alephant::Broker::PostRequest").as_null_object }

    it "should return asset response" do
      instance = Alephant::Broker::ResponseFactory.new({})
      allow(request).to receive(:type).and_return(:asset)

      Alephant::Broker::AssetResponse
        .any_instance
        .stub(:initialize)
        .with(request, {})

      expect(instance.response_from(request))
        .to be_a Alephant::Broker::AssetResponse
    end

    it "should return batched response" do
      instance = Alephant::Broker::ResponseFactory.new({})
      allow(post_request).to receive(:type).and_return(:batch)
      allow(post_request).to receive(:content_type).and_return('application/json')
      allow(post_request).to receive(:set_component)
      allow(post_request).to receive(:components).and_return({
        :batch_id   => 'baz',
        :components => [
          { 'component' => 'foo1', 'variant'   => 'bar1' },
          { 'component' => 'foo2', 'variant'   => 'bar2' }
        ]
      })

      Alephant::Broker::AssetResponse
        .any_instance
        .stub(:initialize)

      expect(instance.response_from(post_request))
        .to be_a Alephant::Broker::BatchResponse
    end

    it "should return status response" do
      allow(request).to receive(:type).and_return(:status)
      response = subject.response_from(request)
      expect(response.status).to eq(200)
    end

    it "should return 404 response" do
      allow(request).to receive(:type).and_return(:notfound)
      response = subject.response_from(request)
      expect(response.status).to eq(404)
    end

    it "should return 500 response" do
      allow(request).to receive(:type).and_return(:error)
      response = subject.response_from(request)
      expect(response.status).to eq(500)
    end
  end
end
