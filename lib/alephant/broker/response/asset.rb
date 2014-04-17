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
          result  = load(component)

          @status  = result['status']
          @content = result['body']
        end

      end
    end
  end
end

