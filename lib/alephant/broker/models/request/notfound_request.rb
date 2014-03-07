require 'alephant/logger'

module Alephant
  module Broker
    class NotFoundRequest
      attr_reader :type

      def initialize
        logger.info("Broker.request: Type: notfound")
        @type = :notfound
      end
    end
  end
end
