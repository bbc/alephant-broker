require 'dalli'
require 'alephant/logger'

module Alephant
  module Broker
    module Cache
      class Client
        include Logger

        DEFAULT_TTL = 2_592_000

        def initialize
          if config_endpoint.nil?
            logger.error(
              method:  'Broker::Cache::Client#initialize',
              message: 'No config endpoint, NullClient used'
            )
            logger.metric 'NoConfigEndpoint'
            @client = NullClient.new
          else
            @client ||= Dalli::Client.new(config_endpoint, expires_in: ttl)
          end
        end

        def get(key)
          versioned_key = versioned(key)
          result        = @client.get(versioned_key)

          logger.debug(
            method: 'Broker::Cache::Client#get',
            key:    versioned_key,
            result: result ? 'hit' : 'miss'
          )
          logger.metric('GetKeyMiss') unless result

          return result if result

          set(key, yield) if block_given?
        end

        def set(key, value, custom_ttl = nil)
          versioned_key = versioned(key)
          set_ttl       = custom_ttl || ttl

          logger.debug(
            method: "#{self.class}#set",
            key:    versioned_key,
            ttl:    set_ttl
          )

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
