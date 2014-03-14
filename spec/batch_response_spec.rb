require 'spec_helper'

describe Alephant::Broker::BatchResponse do
  let (:config) {{
    :lookup_table_name => 'test_table',
    :bucket_id => 'test_bucket',
    :path => 'test_path'
  }}

  let (:post_request) {
    double(
      'Alephant::Broker::PostRequest',
      :options       => {},
      :type          => :batch,
      :content_type  => 'application/json',
      :set_component => nil,
      :component_id  => nil,
      :components    => {
        :batch_id   => :baz,
        :components => [
          { 'component' => 'foo1', 'options' => { 'variant' => 'bar1' } },
          { 'component' => 'foo2', 'options' => { 'variant' => 'bar2' } }
        ]}
    )
  }

  before do
    @lookup_table = double('Alephant::Lookup::LookupTable', :read => 'test_location')
    Alephant::Lookup.stub(:create).and_return(@lookup_table)
    Alephant::Cache.any_instance.stub(:initialize)
    Alephant::Cache.any_instance.stub(:get).and_return('Test response')
  end

  describe "#process" do
    context "if a component is unrecognised" do
      before(:each) do
        Alephant::Cache
          .any_instance
          .stub(:get)
          .and_raise(Alephant::Broker::InvalidCacheKey)

        instance       = Alephant::Broker::BatchResponse.new(post_request, config)
        json           = JSON.parse(instance.process.content)
        @bad_component = json.fetch('components')[1]
      end

      it "set status to 404" do
        expect(@bad_component['status']).to eq(404)
      end

      it "remove 'body' key" do
        expect(@bad_component['body']).to eq(nil)
      end
    end

    context "if a component is recognised" do
      before(:each) do
        @instance = Alephant::Broker::BatchResponse.new(post_request, config)
        @content  = @instance.process.content
        @json     = JSON.parse(@content)
      end

      it "set status to 200" do
        @json.fetch('components').each do |component|
          expect(component['status']).to eq(200)
        end
      end

      it "set @content to be JSON string containing retrieved components" do
        compiled_json = '{"batch_id":"baz","components":[{"component":"foo1","options":{"variant":"bar1"},"status":200,"body":"Test response"},{"component":"foo2","options":{"variant":"bar2"},"status":200,"body":"Test response"}]}'
        expect(@content).to eq(compiled_json)
      end
    end
  end
end
