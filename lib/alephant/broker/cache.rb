require 'dalli-elasticache'

module Dalli
  class ElastiCache
    def servers
      data[:instances].map{ |i| "localhost:11211" }
    end
  end
end

module Alephant
  module Broker
    class Cache

      DEFAULT_CONFIG_ENDPOINT = 'localhost:11211'
      DEFAULT_TTL             = 2592000

      def initialize
        @elasticache = ::Dalli::ElastiCache.new(config_endpoint, { :expires_in => ttl })
        @client = @elasticache.client
      end

      def config_endpoint
        Broker.config['elasticache_config'] || DEFAULT_CONFIG_ENDPOINT
      end

      def ttl
         Broker.config['elasticache_ttl'] || DEFAULT_TTL
      end

      def get(key)
        (result = @client.get(key)) ? result : set(key, yield)
      end

      def set(key, value)
        value.tap { |o| @client.set(key, o) }
      end

    end
  end
end

