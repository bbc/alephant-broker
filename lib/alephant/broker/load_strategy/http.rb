require 'alephant/broker/cache'
require 'alephant/broker/errors/content_not_found'
require 'faraday'

module Alephant
  module Broker
    module LoadStrategy
      class HTTP
        class RequestFailed < StandardError; end

        class URL
          def generate
            raise NotImplementedError
          end
        end

        def initialize(url_strategy)
          @cache = Cache::Client.new
          @url_strategy = url_strategy
        end

        def load(component_meta)
          cache_object(component_meta)
        rescue
          cache.set(component_meta.cache_key, request(component_meta))
        end

        private

        attr_reader :cache, :url_strategy

        def cache_object(component_meta)
          cache.get(component_meta.cache_key) do
            request component_meta
          end
        end

        def request(component_meta)
          component_meta.cached = false

          Faraday.get(url_strategy.generate component_meta.options)
                  tap { |r| raise ContentNotFound if not r.success? }.
                  body
        rescue => e
          raise RequestFailed, e # What would catch this ? Should be one rescued to create a ServerError
        end
      end
    end
  end
end
