require "spec_helper"

RSpec.describe Alephant::Broker::LoadStrategy::Revalidate::Strategy do
  subject { described_class.new }

  let(:cache_double)   { instance_double(Alephant::Broker::Cache::Client) }
  let(:lookup_double)  { instance_double(Alephant::Lookup::LookupHelper) }
  let(:storage_double) { instance_double(Alephant::Storage) }
  let(:refresher_double) { instance_double(Alephant::Broker::LoadStrategy::Revalidate::Refresher, :refresh => nil) }
  let(:fetcher_double) { instance_double(Alephant::Broker::LoadStrategy::Revalidate::Fetcher, :fetch => content) }

  let(:content_body) { "<h1>w00t!</h1>" }
  let(:content_type) { "text/html" }
  let(:content) { { :content => content_body, :content_type => content_type } }

  let(:cached_obj) do
    Alephant::Broker::Cache::CachedObject.new(content_body, content_type)
  end

  let(:component_meta) do
    Alephant::Broker::ComponentMeta.new("test", "test_batch", {})
  end

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)
    allow(Alephant::Broker::Cache::Client).to receive(:new) { cache_double }
    allow(Thread).to receive(:new).and_yield
  end

  describe "#load" do
    context "when there is content in the cache" do
      before do
        allow(cache_double).to receive(:get).and_return(cached_obj)
      end

      context "which is still fresh" do
        before do
          allow(cached_obj).to receive(:expired?).and_return(false)
        end

        it "gets fetched from the cache and returned" do
          expect(subject.load(component_meta)).to eq(content)
        end

        it "does NOT try to refresh the content" do
          expect(Alephant::Broker::LoadStrategy::Revalidate::Refresher)
            .to_not receive(:new)

          subject.load(component_meta)
        end
      end

      context "which has expired" do
        before do
          allow(cached_obj).to receive(:expired?).and_return(true)
          expect(Alephant::Broker::LoadStrategy::Revalidate::Refresher)
            .to receive(:new)
            .with(component_meta)
            .and_return(refresher_double)
        end

        it "gets fetched from the cache and returned" do
          expect(subject.load(component_meta)).to eq(content)
        end

        it "kicks off a refresh of the content" do
          expect(refresher_double).to receive(:refresh)

          subject.load(component_meta)
        end
      end
    end

    context "when there is NOT content in the cache" do
      before do
        expect(cache_double).to receive(:get).and_yield
        expect(Alephant::Broker::LoadStrategy::Revalidate::Fetcher)
          .to receive(:new)
          .with(component_meta)
          .and_return(fetcher_double)
      end

      it "returns the data as expected" do
        expect(fetcher_double).to receive(:fetch).and_return(cached_obj)
        expect(subject.load(component_meta)).to eq(content)
      end

      it "uses the fetcher to get the data" do
        expect(fetcher_double).to receive(:fetch).and_return(cached_obj)
        subject.load(component_meta)
      end

      context "and there is nothing returned from the fetcher" do
        before do
          expect(fetcher_double)
            .to receive(:fetch)
            .and_raise(Alephant::Broker::Errors::ContentNotFound)

          expect(Alephant::Broker::LoadStrategy::Revalidate::Refresher)
            .to receive(:new)
            .with(component_meta)
            .and_return(refresher_double)
        end

        it "raises a Alephant::Broker::Errors::ContentNotFound error, ",
          "and kicks off a refresh of the content" do
          expect(refresher_double).to receive(:refresh)
          expect { subject.load(component_meta) }
            .to raise_error(Alephant::Broker::Errors::ContentNotFound)
        end
      end
    end
  end
end
