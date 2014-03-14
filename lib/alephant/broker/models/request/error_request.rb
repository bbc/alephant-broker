require 'alephant/broker/models/request'

module Alephant
  module Broker
    class ErrorRequest < Request
      def initialize
        super(:error)
      end
    end
  end
end
