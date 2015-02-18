require "dalli-elasticache"

module Alephant
  module Broker
    module Cache
      module Factory
        def self.create
          cache_available? ? Client.new(elasticache.client) : NullClient.new
        end

        def self.cache_available?
          Broker.config['elasticache_config_endpoint']
        end

        def self.elasticache
          @@elasticache ||= ::Dalli::ElastiCache.new(
            Broker.config['elasticache_config_endpoint'],
            {
              :expires_in => ttl
            }
          )
        end
      end
    end
  end
end
