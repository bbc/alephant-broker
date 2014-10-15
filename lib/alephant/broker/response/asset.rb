require 'alephant/logger'

module Alephant
  module Broker
    module Response
      class Asset < Base
        include Logger

        def initialize(component)
          @component = component
          super()
        end

        def setup
          @headers  = @component.headers
          @content  = @component.content
          @sequence = @component.version.nil? ? 'not available'
                                              : @component.version
          log
        end

        private

        def batched
          @component.batch_id.nil? ? '' : 'batched'
        end

        def details
          c = @component
          "#{c.id}/#{c.opts_hash}/#{c.headers} #{batched} #{c.options}"
        end

        def log
          logger.info "Broker: Component loaded! #{details} (200)"
        end
      end
    end
  end
end

