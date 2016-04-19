require "alephant/logger"
require "alephant/broker/component"

module Alephant
  module Broker
    module Request
      class Batch
        include Logger

        attr_reader :batch_id, :components, :load_strategy

        def initialize(component_factory, env)
          logger.info "Request::Batch#initialize: id: #{env.data['batch_id']}"

          @batch_id          = env.data["batch_id"]
          @component_factory = component_factory
          @components        = components_for env
        end

        private

        def components_for(env)
          env.data["components"].map do |c|
            @component_factory.create(
              c["component"],
              batch_id,
              c["options"]
            )
          end
        end
      end
    end
  end
end

