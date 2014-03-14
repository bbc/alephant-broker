$: << File.dirname(__FILE__)

require 'alephant/broker'
require 'alephant/logger'

module Alephant
  module Broker
    class Application
      include Logger

      def initialize(config)
        @config = config
      end

      def handle
        Alephant::Broker.handle(@config)
      end
    end
  end
end
