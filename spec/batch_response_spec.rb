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
    it 'sets @content to be JSON string containing retrieved components' do
      instance = Alephant::Broker::BatchResponse.new(post_request, config)
      compiled_json = '{"batch_id":"baz","components":[{"component":"foo1","body":"Test response"},{"component":"foo2","body":"Test response"}]}'
      expect(instance.process.content).to eq(compiled_json)
    end
  end
end
