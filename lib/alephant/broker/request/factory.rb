require 'alephant/broker/request'
require 'alephant/broker/component_factory'

module Alephant
  module Broker
    module Request
      class Factory
        def self.request_type_from(env)
          env.path.split("/")[1]
        end

        def self.request_for(load_strategy, env)
          component_factory = ComponentFactory.new load_strategy

          case request_type_from(env)
          when "component"
            Asset.new(component_factory, env)
          when "components"
            Batch.new(component_factory, env)
          when "status"
            Status.new
          else
            NotFound.new
          end
        end
      end
    end
  end
end
