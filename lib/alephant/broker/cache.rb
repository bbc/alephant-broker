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
    module Cache
      class Client

        DEFAULT_TTL  = 2592000

        def initialize
          unless config_endpoint.nil?
            @@elasticache ||= ::Dalli::ElastiCache.new(config_endpoint, { :expires_in => ttl })
            @client = @@elasticache.client
          else
            @client = NullClient.new
          end
        end

        def config_endpoint
          Broker.config['elasticache_config_endpoint']
        end

        def ttl
           Broker.config['elasticache_ttl'] || DEFAULT_TTL
        end

        def get(key)
          begin
            (result = @client.get(key)) ? result : set(key, yield)
          rescue StandardError => e
            yield
          end
        end

        def set(key, value)
          value.tap { |o| @client.set(key, o) }
        end

      end

      class NullClient
        def get(key); end

        def set(key, value)
          value
        end
      end

    end
  end
end

