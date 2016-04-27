require "alephant/logger"
require "alephant/broker/component"

module Alephant
  module Broker
    module Request
      class Batch
        include Logger

        attr_reader :batch_id, :components, :load_strategy

        def initialize(component_factory, env)
          if env.data
            @batch_id        = env.data["batch_id"]
          elsif
            @batch_id        = env.options.fetch("batch_id", nil)
          end

          logger.info "Request::Batch#initialize: id: #{batch_id}"

          @component_factory = component_factory

          @components        = env.post? ? components_post(env) : components_get(env)
        end

        private

        def components_post(env)
          ((env.data || {}).fetch("components", []) || []).map do |c|
            create_component(c["component"], batch_id, c["options"])
          end
        end

        def components_get(env)
          (env.options.fetch("components", []) || []).map do |c|
            options = c[1].fetch("options", {}) || {}
            create_component(c[1]["component"], batch_id, options)
          end
        end

        def create_component(component, batch_id, options)
          @component_factory.create(component, batch_id, options)
        end
      end
    end
  end
end

