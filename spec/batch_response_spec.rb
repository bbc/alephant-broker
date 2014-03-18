require 'spec_helper'

describe Alephant::Broker::BatchResponse do
  subject { Alephant::Broker::BatchResponse }

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
      :renderer_id   => nil,
      :components    => {
        :batch_id   => :baz,
        :components => [
          { 'component' => 'foo1', 'options' => { 'variant' => 'bar1' } },
          { 'component' => 'foo2', 'options' => { 'variant' => 'bar2' } }
        ]}
    )
  }

  before do
    Alephant::Broker::AssetResponse
      .any_instance
      .stub(:initialize)
  end

  describe "#process" do
    context "if a component is unrecognised" do
      before(:each) do
        Alephant::Broker::AssetResponse
          .any_instance
          .stub(:status)
          .and_return(404)

        instance       = subject.new(post_request, config)
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
        Alephant::Broker::AssetResponse
          .any_instance
          .stub(:status)
          .and_return(200)

        Alephant::Broker::AssetResponse
          .any_instance
          .stub(:content)
          .and_return('Test')

        @instance = subject.new(post_request, config)
        @content  = @instance.process.content
        @json     = JSON.parse(@content)
      end

      it "set status to 200" do
        @json.fetch('components').each do |component|
          expect(component['status']).to eq(200)
        end
      end

      it "set @content to be JSON string containing retrieved components" do
        compiled_json = '{"batch_id":"baz","components":[{"component":"foo1","options":{"variant":"bar1"},"status":200,"body":"Test"},{"component":"foo2","options":{"variant":"bar2"},"status":200,"body":"Test"}]}'
        expect(@content).to eq(compiled_json)
      end
    end
  end
end
