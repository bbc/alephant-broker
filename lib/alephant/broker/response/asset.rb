require 'alephant/logger'

module Alephant
  module Broker
    module Response
      class Asset < Base
        include Logger

        def initialize(component, request_env)
          @component = component
          @request_env = request_env

          @status = self.class.component_not_modified(@component.headers, request_env) ? NOT_MODIFIED_STATUS_CODE : component.status

          super @status

          @headers.merge!(@component.headers)
        end

        def setup
          @content  = (@request_env.options?) ? "" : @component.content
          log if @component.is_a? Component
        end

        private

        def batched
          @component.batch_id.nil? ? '' : 'batched'
        end

        def details
          c = @component
          "#{c.id}/#{c.options}/#{c.headers} #{batched} #{c.options}"
        end

        def log
          logger.metric "BrokerResponse#{status}"
          logger.info "Broker: Component loaded! #{details} (200)"
        end
      end
    end
  end
end

