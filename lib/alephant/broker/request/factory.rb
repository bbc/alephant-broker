require "alephant/logger"
require "alephant/broker/request"
require "alephant/broker/component_factory"

module Alephant
  module Broker
    module Request
      class Factory
        extend Logger

        def self.request_type_from(env)
          env.path.split("/")[1]
        end

        def self.request_for(load_strategy, env)
          component_factory = ComponentFactory.new(load_strategy)

          logger.increment('request_count')

          case request_type_from(env)
          when "component"
            logger.increment('actionable_request_count')
            Asset.new(component_factory, env)
          when "components"
            logger.increment('actionable_request_count')
            Batch.new(component_factory, env)
          when "status"
            logger.increment('status_request')
            Status.new
          else
            logger.increment('not_found_request')
            NotFound.new
          end
        end
      end
    end
  end
end
