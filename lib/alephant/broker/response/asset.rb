require "alephant/logger"

module Alephant
  module Broker
    module Response
      class Asset < Base
        include Logger

        def initialize(component)
          @component = component
          super component.status
        end

        def setup
          @headers.merge!(@component.headers)
          @content  = @component.content
          log if @component.is_a? Component
        end

        private

        def batched
          @component.batch_id.nil? ? "" : "batched"
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
