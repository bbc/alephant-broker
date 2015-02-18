require "alephant/logger"

module Alephant
  module Broker
    module Cache
      class NullClient
        def initialize
          logger.debug('Broker::Cache::Client#initialize: No config endpoint, NullClient used')
          logger.metric(:name => "BrokerCacheClientNoConfigEndpoint", :unit => "Count", :value => 1)
        end

        def get(key); end

        def set(key, value, ttl = nil)
          value
        end
      end
    end
  end
end
