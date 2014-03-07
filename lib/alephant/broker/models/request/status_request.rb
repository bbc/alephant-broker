require 'alephant/logger'

module Alephant
  module Broker
    class StatusRequest
      include Logger
      attr_reader :type

      def initialize(env)
        logger.info("Broker.request: Type: status")
        @type = :status
      end
    end
  end
end
