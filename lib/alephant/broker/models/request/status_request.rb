require 'alephant/broker/models/request'

module Alephant
  module Broker
    class StatusRequest < Request
      def initialize
        super(:status)
      end
    end
  end
end
