require "spec_helper"

RSpec.describe Alephant::Broker::LoadStrategy::Revalidate::Refresher do
  subject { described_class.new(component_meta) }

  let(:component_meta) do
    Alephant::Broker::ComponentMeta.new("test", "test_batch", {})
  end

  let(:config)  { { :aws_account_id => "12345", :sqs_queue_name => "bob" } }

  let(:cache)              { subject.send(:cache) }
  let(:cache_key)          { subject.send(:cache_key) }
  let(:inflight_cache_key) { subject.send(:inflight_cache_key) }

  let(:queue_url) { 'http://sqs.aws.myqueue/id' }
  let(:fake_client) { Aws::SQS::Client.new(stub_responses: true) }

  before do
    allow(subject).to receive(:client).and_return(fake_client)
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)
    allow(Alephant::Broker).to receive(:config).and_return(config)
  end

  describe "#refresh" do
    context "when there is already a 'inflight' message in the cache" do
      before do
        expect(cache)
          .to receive(:get)
          .with(subject.send(:inflight_cache_key))
          .and_return("true")
      end

      it "does nothing" do
        expect(cache).to_not receive(:set)

        subject.refresh
      end
    end

    context "when there is NOT already a 'inflight' message in the cache" do
      before do
        expect(cache)
          .to receive(:get)
          .with(inflight_cache_key)
          .and_return(nil)
      end

      it "adds a message to the SQS queue, and puts a 'inflight' message in the cache" do
        fake_client.stub_responses(:get_queue_url, { queue_url: queue_url })

        expect(fake_client).to receive(:send_message)

        expect(cache).to receive(:set).with(inflight_cache_key, true, described_class::INFLIGHT_CACHE_TTL)

        subject.refresh
      end

      context "there was a problem pushing a message onto the queue" do
        it "does NOT put an 'inflight' message in the cache" do
          expect(cache).to_not receive(:set)

          expect(fake_client).to receive(:send_message).and_raise

          expect { subject.refresh }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
