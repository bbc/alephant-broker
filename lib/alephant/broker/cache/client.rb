require "alephant/logger"

module Alephant
  module Broker
    module Cache
      class Client
        include Logger
        attr_reader :driver

        DEFAULT_TTL  = 2592000

        def initialize(driver)
          @driver = driver
        end

        def get(key, &block)
          begin
            fetch_from_driver(versioned(key)) or set(key, block.call)
          rescue StandardError
            block.call if block_given?
          end
        end

        def set(key, value, ttl = nil)
          value.tap { |o| driver.set(versioned(key), o, ttl) }
        end

        private

        def fetch_from_driver(key)
          driver.get(key).tap do |result|
            logger.info("Broker::Cache::Client#get key: #{key} - #{result ? 'hit' : 'miss'}")
            logger.metric(:name => "BrokerCacheClientGetKeyMiss", :unit => "Count", :value => 1) unless result
          end
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
    end
  end
end
