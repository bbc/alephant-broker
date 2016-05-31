require "alephant/broker/cache"
require "alephant/broker/errors"
require "alephant/logger"
require "alephant/broker/load_strategy/revalidate/refresher"
require "alephant/broker/load_strategy/revalidate/fetcher"
require "faraday"

module Alephant
  module Broker
    module LoadStrategy
      module Revalidate
        class Strategy
          include Logger

          def load(component_meta)
            loaded_content = cached_object(component_meta)

            refresh_content(component_meta) if loaded_content.expired?

            data = loaded_content.to_h
            data.fetch(:meta, {})["status"] = 200
            data
          rescue Alephant::Broker::Errors::ContentNotFound
            refresh_content(component_meta)

            {
              :content      => "",
              :content_type => "text/html",
              :meta         => { "status" => 202 }
            }
          end

          private

          attr_reader :cache

          def cache
            @cache ||= Cache::Client.new
          end

          def refresh_content(component_meta)
            Thread.new do
              logger.info "Loading new content from thread"
              Refresher.new(component_meta).refresh
            end
          end

          def cached_object(component_meta)
            cache.get(component_meta.component_key) do
              logger.info "No cache so loading and adding cache object"
              Fetcher.new(component_meta).fetch
            end
          end
        end
      end
    end
  end
end
