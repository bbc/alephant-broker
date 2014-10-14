require 'alephant/logger'
require 'alephant/broker/component'
require 'peach'


module Alephant
  module Broker
    module Request
      class Batch
        include Logger

        attr_reader :batch_id, :components, :load_strategy

        def initialize(component_factory, env)
          logger.debug("Request::Batch#initialize(#{env.settings})")

          @component_factory = component_factory
          @batch_id   = env.data['batch_id']
          @components = components_for env

          logger.debug("Request::Batch#initialize: id: #{@batch_id}")
        end

        private

        def components_for(env)
          env.data['components'].map do |c|
            @component_factory.create(
              c['component'],
              batch_id,
              c['options']
            )
          end
        end

      end
    end
  end
end

