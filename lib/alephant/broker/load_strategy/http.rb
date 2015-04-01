require 'alephant/broker/cache'
require 'alephant/broker/errors/content_not_found'
require 'alephant/logger'
require 'faraday'

module Alephant
  module Broker
    module LoadStrategy
      class HTTP
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
          cache_object(component_meta)
        rescue
          logger.metric(
            "BrokerLoadStrategyHTTPCacheMiss",
            opts[:dimensions].merge(:function => "load")
          )
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
          before = Time.new
          component_meta.cached = false

          Faraday.get(url_for component_meta).tap do |r|
            unless r.success?
              logger.metric(
                "BrokerLoadStrategyHTTPContentNotFound",
                opts[:dimensions].merge(:function => "request")
              )
              raise Alephant::Broker::Errors::ContentNotFound
            end

            request_time = Time.new - before
            logger.metric("BrokerHTTPLoadComponentTime", opts.merge(
              :unit  => "Seconds", :value => request_time,
            ).tap { |h| h[:dimensions].merge!(:function => "request") })
          end
        end

        def url_for(component_meta)
          url_generator.generate(
            component_meta.id,
            component_meta.options
          )
        end

        def opts
          {
            :dimensions => {
              :module   => "AlephantBrokerLoadStrategy",
              :class    => "HTTP"
            }
          }
        end
      end
    end
  end
end
