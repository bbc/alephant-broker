require 'alephant/logger'

module Alephant
  module Broker
    class Request
      include Logger
      attr_reader :type

      def initialize(request_type)
        logger.info("Broker.request: Type: #{request_type}")
        @type = request_type
      end
    end
  end
end
