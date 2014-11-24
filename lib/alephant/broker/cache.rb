require 'dalli-elasticache'
require 'alephant/logger'

module Alephant
  module Broker
    module Cache
      class Client
        include Logger

        DEFAULT_TTL  = 2592000

        def initialize
          unless config_endpoint.nil?
            @@elasticache ||= ::Dalli::ElastiCache.new(config_endpoint, { :expires_in => ttl })
            @@client ||= @@elasticache.client
          else
            logger.debug('Broker::Cache::Client#initialize: No config endpoint, NullClient used')
            logger.metric(:name => "BrokerCacheClientNoConfigEndpoint", :unit => "Count", :value => 1)
            @@client = NullClient.new
          end
        end

        def get(key, &block)
          begin
            result = @@client.get(versioned(key))
            logger.info("Broker::Cache::Client#get key: #{key} - #{result ? 'hit' : 'miss'}")
            logger.metric(:name => "BrokerCacheClientGetKeyMiss", :unit => "Count", :value => 1) unless result
            result ? result : set(key, block.call)
          rescue StandardError => e
            block.call if block_given?
          end
        end

        def set(key, value, ttl = nil)
          value.tap { |o| @@client.set(versioned(key), o, ttl) }
        end

        private

        def config_endpoint
          Broker.config['elasticache_config_endpoint']
        end

        def ttl
           Broker.config['elasticache_ttl'] || DEFAULT_TTL
        end

        def versioned(key)
          [key, cache_version].compact.join('_')
        end

        def cache_version
          Broker.config['elasticache_cache_version']
        end
      end

      class NullClient
        def get(key); end

        def set(key, value, ttl = nil)
          value
        end
      end
    end
  end
end

