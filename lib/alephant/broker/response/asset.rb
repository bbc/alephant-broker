require 'alephant/logger'

module Alephant
  module Broker
    module Response
      class Asset < Base
        include Logger

        def initialize(component, env)
          @component = component
          @env = env
          super component.status
        end

        def setup
          @headers.merge!(@component.headers)

          if component_not_modified(@component.headers, @env)
            @status = 304
            return
          end

          @content  = @component.content
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

