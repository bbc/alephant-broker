$: << File.dirname(__FILE__)

require 'alephant/broker'

module Alephant
  module Broker
    class Application
      def initialize(config)
        @config = config
      end

      def handle(env)
        Alephant::Broker.handle(env, @config)
      end
    end
  end
end
