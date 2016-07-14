require 'spec_helper'

RSpec.describe Alephant::Broker::LoadStrategy::Revalidate::Strategy do
  subject { described_class.new }

  let(:lookup_double)    { instance_double(Alephant::Lookup::LookupHelper) }
  let(:storage_double)   { instance_double(Alephant::Storage) }
  let(:refresher_double) { instance_double(Alephant::Broker::LoadStrategy::Revalidate::Refresher) }
  let(:fetcher_double)   { instance_double(Alephant::Broker::LoadStrategy::Revalidate::Fetcher) }

  let(:content) do
    {
      content:      'Test',
      content_type: 'test/content',
      meta:         {
        :ttl                  => 100,
        :head_ETag            => '123',
        :'head_Last-Modified' => Time.now.to_s
      }
    }
  end

  let(:expected_content) do
    {
      content:      content[:content],
      content_type: content[:content_type],
      meta:         content[:meta]
    }
  end

  let(:cached_obj) do
    Alephant::Broker::Cache::CachedObject.new(content)
  end

  let(:component_meta) do
    Alephant::Broker::ComponentMeta.new('test', 'test_batch', {})
  end

  before do
    allow_any_instance_of(Logger).to receive(:info)
    allow_any_instance_of(Logger).to receive(:debug)
    allow(Alephant::Broker).to receive(:config).and_return({})
    allow(Thread).to receive(:new).and_yield
  end

  describe '#load' do
    context 'when there is content in the cache' do
      let(:cache) { subject.send(:cache) }

      before do
        allow(cache).to receive(:get).and_return(cached_obj)
      end

      context 'which is still fresh' do
        before do
          allow(cached_obj).to receive(:expired?).and_return(false)
        end

        it 'gets fetched from the cache and returned' do
          expect(subject.load(component_meta)).to eq(expected_content)
        end

        it 'does NOT try to refresh the content' do
          expect(Alephant::Broker::LoadStrategy::Revalidate::Refresher)
            .to_not receive(:new)

          subject.load(component_meta)
        end
      end

      context 'which has expired' do
        before do
          allow(cached_obj).to receive(:expired?).and_return(true)

          allow(Alephant::Broker::LoadStrategy::Revalidate::Refresher)
            .to receive(:new)
            .with(component_meta)
            .and_return(refresher_double)

          allow(refresher_double).to receive(:refresh)

          allow(Alephant::Broker::LoadStrategy::Revalidate::Fetcher)
            .to receive(:new)
            .with(component_meta)
            .and_return(fetcher_double)

          allow(fetcher_double).to receive(:fetch).and_return(cached_obj)
        end

        it 'it gets fetched from the cache and returned to the user' do
          expect(subject.load(component_meta)).to eq(expected_content)
        end

        context 'in the background...' do
          let(:new_content)    { { id: 'test', batch_id: '', meta: {} } }
          let(:new_cached_obj) { Alephant::Broker::Cache::CachedObject.new(new_content) }

          it 'checks the fetcher, to see if there is newer content (in S3)' do
            expect(fetcher_double).to receive(:fetch).and_return(new_cached_obj)

            subject.load(component_meta)
          end

          context 'when there IS newer, non-expired content' do
            let(:cache) { subject.send(:cache) }

            before do
              expect(fetcher_double).to receive(:fetch).and_return(new_cached_obj)
              expect(new_cached_obj).to receive(:expired?).and_return(false)
            end

            it 'replaces the cached content' do
              expect(cache).to receive(:set).with(component_meta.component_key, new_cached_obj)

              subject.load(component_meta)
            end
          end

          context 'when there IS NOT newer content' do
            before do
              expect(fetcher_double).to receive(:fetch).and_return(new_cached_obj)
              expect(new_cached_obj).to receive(:expired?).and_return(true)
            end

            it 'kicks off a refresh of the content (from the renderer)' do
              expect(refresher_double).to receive(:refresh)

              subject.load(component_meta)
            end
          end
        end
      end
    end

    context 'when there is NOT content in the cache' do
      before do
        allow(Alephant::Broker::LoadStrategy::Revalidate::Fetcher)
          .to receive(:new)
          .with(component_meta)
          .and_return(fetcher_double)
      end

      it 'returns the data as expected' do
        expect(fetcher_double).to receive(:fetch).and_return(cached_obj)
        expect(subject.load(component_meta)).to eq(expected_content)
      end

      it 'uses the fetcher to get the data' do
        expect(fetcher_double).to receive(:fetch).and_return(cached_obj)
        subject.load(component_meta)
      end

      context 'and there is nothing returned from the fetcher' do
        before do
          allow(fetcher_double)
            .to receive(:fetch)
            .and_raise(Alephant::Broker::Errors::ContentNotFound)

          expect(Alephant::Broker::LoadStrategy::Revalidate::Refresher)
            .to receive(:new)
            .with(component_meta)
            .and_return(refresher_double)

          allow(refresher_double)
            .to receive(:refresh)
        end

        it 'kicks off a refresh of the content' do
          expect(refresher_double).to receive(:refresh)
          subject.load(component_meta)
        end

        it 'returns a response that will invoke a 202 (HTTP) response' do
          expected_response = {
            content:      '',
            content_type: 'text/html',
            meta:         { status: 202 }
          }

          expect(subject.load(component_meta)).to eq(expected_response)
        end
      end
    end
  end
end
