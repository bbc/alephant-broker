require 'spec_helper'

describe Alephant::Broker::PostRequest do
  subject { Alephant::Broker::PostRequest }

  describe "#components" do
    it "returns hash of component parts + sub components" do
      components = [{
        "component" => "qux",
        "options"   => { "variant" => "cor" }
      }]

      env = (Struct.new(:path, :data)).new("/foo/bar", {
        'batch_id'    => :foobar,
        'components'  => components
      })

      hash = {
        :batch_id     => :foobar,
        :type         => "foo",
        :component_id => "bar",
        :components   => components
      }

      RequestStore
        .stub(:store)
        .and_return({
          :env => env
        })

      instance = subject.new
      expect(instance.components).to eq(hash)
    end
  end

  describe "#set_component(id, options)" do
    it "sets instance attribute values" do
      subject
        .any_instance
        .stub(:initialize)

      instance = subject.new
      instance.set_component(:foo, :bar)

      expect(instance.component_id).to eq(:foo)
      expect(instance.options).to eq(:bar)
    end
  end
end
