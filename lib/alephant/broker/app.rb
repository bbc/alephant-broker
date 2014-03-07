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

      def handle(env)
        Alephant::Broker.handle(env, @config)
      end
    end
  end
end
