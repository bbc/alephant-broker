require 'alephant/logger'
require 'alephant/broker/component'

module Alephant
  module Broker
    module Request
      class Multi
        include Logger

        attr_reader :requests

        def initialize(env)
          logger.debug("Request::Multi#initialize(#{env.settings})")
          @requests = requests_for env
        end

        private

        def requests_for(env)
          env.data['requests'].map do |c|
            case c['type']
            when 'asset'
              asset = Asset.new

              component_id = c['payload']['component_id']
              options      = c['payload']['options']

              component = Component.new(component_id, nil, options)
              asset.tap { |a| a.component = component }
            else
              raise StandardError.new "request type not identified"
            end
          end
        end

      end
    end
  end
end

