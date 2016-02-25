require "dalli-elasticache"
require "alephant/logger"

module Alephant
  module Broker
    module Cache
      class Client
        include Logger

        DEFAULT_TTL  = 2_592_000

        def initialize
          unless config_endpoint.nil?
            @@elasticache ||= ::Dalli::ElastiCache.new(config_endpoint, :expires_in => ttl)
            @@client ||= @@elasticache.client
          else
            logger.debug "Broker::Cache::Client#initialize: No config endpoint, NullClient used"
            logger.metric "NoConfigEndpoint"
            @@client = NullClient.new
          end
        end

        def get(key, &block)
          versioned_key = versioned key
          result = @@client.get versioned_key
          logger.info "Broker::Cache::Client#get key: #{versioned_key} - #{result ? 'hit' : 'miss'}"
          logger.metric "GetKeyMiss" unless result
          result ? result : set(key, block.call)
        rescue StandardError => e
          block.call if block_given?
        end

        def set(key, value, ttl = nil)
          value.tap { |o| @@client.set(versioned(key), o, ttl) }
        end

        private

        def config_endpoint
          Broker.config["elasticache_config_endpoint"]
        end

        def ttl
          Broker.config["elasticache_ttl"] || DEFAULT_TTL
        end

        def versioned(key)
          [key, cache_version].compact.join("_")
        end

        def cache_version
          Broker.config["elasticache_cache_version"]
        end
      end

      class NullClient
        def get(key); end

        def set(_key, value, _ttl = nil)
          value
        end
      end
    end
  end
end
