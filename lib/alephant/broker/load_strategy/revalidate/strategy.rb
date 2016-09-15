require 'alephant/broker/cache'
require 'alephant/broker/errors'
require 'alephant/logger'
require 'alephant/broker/load_strategy/revalidate/refresher'
require 'alephant/broker/load_strategy/revalidate/fetcher'
require 'faraday'

module Alephant
  module Broker
    module LoadStrategy
      module Revalidate
        class Strategy
          include Logger

          STORAGE_ERRORS = [Alephant::Broker::Errors::ContentNotFound].freeze

          def load(component_meta)
            loaded_content = cached_object(component_meta)

            update_content(component_meta) if loaded_content.expired?

            data = loaded_content.to_h
            data.fetch(:meta, {})[:status] = 200
            add_revalidating_headers(data) if loaded_content.expired?

            data
          rescue *STORAGE_ERRORS
            update_content(component_meta)

            {
              content:      '',
              content_type: 'text/html',
              meta:         { status: 202 }
            }
          end

          private

          attr_reader :cache

          def cache
            @cache ||= Cache::Client.new
          end

          def cached_object(component_meta)
            cache.get(component_meta.component_key) do
              logger.info(msg: "#{self.class}#cached_object - No cache so loading and adding cache object")
              Fetcher.new(component_meta).fetch
            end
          end

          def update_content(component_meta)
            Thread.new do
              stored_content = fetch_stored_content(component_meta)

              if stored_content && !stored_content.expired?
                cache_new_content(component_meta, stored_content)
              else
                refresh_content(component_meta)
              end
            end
          end

          def add_revalidating_headers(data)
             data[:headers] ||= {}
             data[:headers]['Access-Control-Expose-Headers'] = 'broker-cache'
             data[:headers]['broker-cache'] = 'revalidating'
          end

          def fetch_stored_content(component_meta)
            Fetcher.new(component_meta).fetch
          rescue *STORAGE_ERRORS
            nil
          end

          def cache_new_content(component_meta, new_content)
            logger.info(event:  'NewContentFromS3',
                        key:    component_meta.component_key,
                        val:    new_content,
                        method: "#{self.class}#refresh_content")

            cache.set(component_meta.component_key, new_content)
          end

          def refresh_content(component_meta)
            logger.info(msg: "#{self.class}#refresh_content - Loading new content from thread")

            Refresher.new(component_meta).refresh
          end
        end
      end
    end
  end
end
