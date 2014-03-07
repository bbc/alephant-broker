require 'alephant/logger'

module Alephant
  module Broker
    class ErrorRequest
      include Logger
      attr_reader :type

      def initialize
        logger.info("Broker.request: Type: error")
        @type = :error
      end
    end
  end
end