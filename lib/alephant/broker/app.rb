$: << File.dirname(__FILE__)

require 'alephant/broker'
require 'alephant/broker/models/request'

module Alephant
  module Broker
    class Application
      def initialize(config)
        @config = config
      end

      def handle(request)
        Alephant::Broker.handle(request, @config)
      end

      def request_from(path, querystring)
        Request.new(path, querystring)
      end

    end
  end
end