require 'spec_helper'

describe Alephant::Broker::GetRequest do
  subject { Alephant::Broker::GetRequest }

  before(:each) do
    subject.any_instance.stub(:initialize)
  end

  describe "#requested_components" do
    it "returns hash of component parts" do
      result = subject.new.requested_components('/foo/bar', 'baz=qux')
      hash   = {
        :type         => "foo",
        :component_id => "bar",
        :extension    => :html,
        :options      => { :baz => "qux" }
      }

      expect(result).to eq(hash)
    end
  end

  describe "#parse" do
    context "when component_id is nil" do
      it "raise error" do
        expect {
          subject.new.parse :extension => :foobar
        }.to raise_exception
      end
    end

    context "when component_id is not nil" do
      it "sets values for attr_reader's" do
        request = {
          :component_id => 'foo',
          :extension => 'bar',
          :options => 'baz'
        }

        instance = subject.new
        instance.parse(request)

        expect(instance.component_id).to eq('foo')
        expect(instance.extension).to    eq('bar')
        expect(instance.options).to      eq('baz')
      end

      context "and extension is recognised" do
        it "sets appropriate value for instance attribute" do
          request = { :extension => 'json', :component_id => 'foo' }

          instance = subject.new
          instance.parse(request)

          expect(instance.content_type).to eq('application/json')
        end
      end

      context "and extension is not recognised" do
        it "sets default value for instance attribute" do
          request = { :extension => 'foobar', :component_id => 'foo' }

          instance = subject.new
          instance.parse(request)

          expect(instance.content_type).to eq('text/html')
        end
      end
    end
  end
end
