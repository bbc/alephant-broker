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
          component_factory = ComponentFactory.new load_strategy

          logger.metric('RequestCount')

          case request_type_from(env)
          when "component"
            logger.metric('ActionableRequestCount')
            Asset.new(component_factory, env)
          when "components"
            logger.metric('ActionableRequestCount')
            Batch.new(component_factory, env)
          when "status"
            logger.metric('StatusRequest')
            Status.new
          else
            logger.metric('NotFoundRequest')
            NotFound.new
          end
        end
      end
    end
  end
end
