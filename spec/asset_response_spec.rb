require 'spec_helper'

describe Alephant::Broker::AssetResponse do
  subject { Alephant::Broker::AssetResponse }

  describe "#initialize(request, config)" do
    let(:location) { 'test_location' }

    let(:config) {{
      :lookup_table_name => 'test_table',
      :bucket_id => 'test_bucket',
      :path => 'test_path'
    }}

    let(:request) { double(
                      "Alephant::Broker::Request",
                      :component_id => 'test',
                      :content_type => 'text/html',
                      :type         => :asset,
                      :options      => { :variant => 'test_variant' }
                    )
                  }

    before do
      subject
        .any_instance
        .stub(:s3_path)
        .and_return(:foo)
    end

    context "successful" do
      before(:each) do
        subject
          .any_instance
          .stub(:cache)
          .and_return(double(:get => 'Test'))
      end

      it "Should return the content from a successful cache lookup" do
        instance = subject.new(request, config)

        expect(instance.content).to eq('Test')
        expect(instance.status).to eq(200)
      end
    end

    context "client failure" do
      before(:each) do
        subject
          .any_instance
          .stub(:cache)
          .and_raise(Alephant::Broker::InvalidCacheKey)
      end

      it "should return a 404 if lookup can't find a valid location" do
        instance = subject.new(request, config)
        expect(instance.status).to eq(404)
      end
    end

    context "server failure" do
      before(:each) do
        subject
          .any_instance
          .stub(:cache)
          .and_raise(Exception)
      end

      it "should return a 500 for any other exceptions" do
        instance = subject.new(request, config)
        expect(instance.status).to eq(500)
      end
    end
  end
end



