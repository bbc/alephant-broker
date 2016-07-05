require 'dalli-elasticache'
require 'alephant/logger'

module Alephant
  module Broker
    module Cache
      class Client
        include Logger

        DEFAULT_TTL = 2_592_000

        def initialize
          if config_endpoint.nil?
            logger.debug 'Broker::Cache::Client#initialize: No config endpoint, NullClient used'
            logger.metric 'NoConfigEndpoint'
            @client = NullClient.new
          else
            @elasticache ||= ::Dalli::ElastiCache.new(config_endpoint, expires_in: ttl)
            @client ||= @elasticache.client
          end
        end

        def get(key)
          versioned_key = versioned(key)
          result        = @client.get(versioned_key)

          logger.info("Broker::Cache::Client#get key: #{versioned_key} - #{result ? 'hit' : 'miss'}")
          logger.metric('GetKeyMiss') unless result

          return result if result

          set(key, yield) if block_given?
        rescue StandardError
          yield if block_given?
        end

        def set(key, value, custom_ttl = nil)
          versioned_key = versioned(key)
          set_ttl       = custom_ttl || ttl

          logger.info("#{self.class}#set - key: #{versioned_key}, ttl: #{set_ttl}, value: #{value}")

          @client.set(versioned_key, value, set_ttl)

          value
        end

        private

        def config_endpoint
          Broker.config[:elasticache_config_endpoint] || Broker.config['elasticache_config_endpoint']
        end

        def ttl
          Broker.config[:elasticache_ttl] || Broker.config['elasticache_ttl'] || DEFAULT_TTL
        end

        def versioned(key)
          [key, cache_version].compact.join('_')
        end

        def cache_version
          Broker.config[:elasticache_cache_version] || Broker.config['elasticache_cache_version']
        end
      end
    end
  end
end
