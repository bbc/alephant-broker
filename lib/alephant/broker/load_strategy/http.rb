require 'alephant/broker/cache'
require 'alephant/broker/errors/content_not_found'
require 'faraday'

module Alephant
  module Broker
    module LoadStrategy
      class HTTP
        class URL
          def generate
            raise NotImplementedError
          end
        end

        def initialize(url_generator)
          @url_generator = url_generator
        end

        def load(component_meta)
          cache_object(component_meta)
        rescue
          cache.set(component_meta.cache_key, content(component_meta))
        end

        private

        attr_reader :cache, :url_generator

        def cache
          @cache ||= Cache::Client.new
        end

        def cache_object(component_meta)
          cache.get(component_meta.cache_key) { content component_meta }
        end

        def content(component_meta)
          resp = request component_meta
          {
            :content => resp.body,
            :content_type => extract_content_type_from(resp.env.response_headers)
          }
        end

        def extract_content_type_from(headers)
          headers['content-type'].split(';').first
        end

        def request(component_meta)
          component_meta.cached = false
          Faraday.get(url_for component_meta).
                  tap { |r| raise ContentNotFound unless r.success? }
        end

        def url_for(component_meta)
          url_generator.generate(
            component_meta.id,
            component_meta.options
          )
        end
      end
    end
  end
end
