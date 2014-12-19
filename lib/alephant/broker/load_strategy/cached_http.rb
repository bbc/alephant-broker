require 'alephant/broker/cache'
require 'alephant/broker/errors/content_not_found'
require 'faraday'
require 'alephant/broker/load_strategy/cache_object'
require 'alephant/logger'

module Alephant
  module Broker
    module LoadStrategy
      class CachedHTTP
        include Logger

        class URL
          def generate
            raise NotImplementedError
          end
        end

        def initialize(url_generator)
          @url_generator = url_generator
        end

        def load(component_meta)
          loaded_content = cache_object(component_meta)

          if loaded_content.expired? && !loaded_content.validating?
            Thread.new do
              logger.info "Loading new content from thread"
              loaded_content.now_validating
              cache.set(component_meta.cache_key, loaded_content)
              loaded_content.update(content(component_meta))
              cache.set(component_meta.cache_key, loaded_content)
            end
          end

          {
            :content => loaded_content.content,
            :content_type => loaded_content.content_type
          }
        end

        private

        attr_reader :cache, :url_generator

        def cache
          @cache ||= Cache::Client.new
        end

        def cache_object(component_meta)
          cache.get(component_meta.cache_key) do
            logger.info "No cache so loading and adding cache object"
            loaded_content = content(component_meta)
            Alephant::Broker::LoadStrategy::CacheObject.new(loaded_content[:content], loaded_content[:content_type])
          end
        end

        def content(component_meta)
          resp         = request component_meta
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
          Faraday.get(url_for component_meta).tap do |r|
            raise Alephant::Broker::Errors::ContentNotFound unless r.success?
          end
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
