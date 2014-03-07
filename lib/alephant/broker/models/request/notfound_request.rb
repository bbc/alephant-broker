require 'alephant/broker/models/request'

module Alephant
  module Broker
    class NotFoundRequest < Request
      def initialize
        super(:notfound)
      end
    end
  end
end
