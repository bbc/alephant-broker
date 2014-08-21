require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/logger'

module Alephant
  module Broker
    module Response
      class Asset < Base
        include Logger

        attr_reader :component

        def initialize(component)
          @component = component
          super()
        end

        def setup
          loaded_content = load(component)

          @content      = loaded_content[:body]
          @content_type = loaded_content[:content_type]
          @status       = loaded_content[:status]
          @sequence     = component.version.nil? ? 'not available' : component.version
          @cached       = component.cached
        end

      end
    end
  end
end

