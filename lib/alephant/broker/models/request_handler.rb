require 'alephant/broker/models/request'
require 'alephant/broker/models/response_factory'

module Alephant
  module Broker
    class RequestHandler

      def initialize(config)
        @response_factory = ResponseFactory.new(config)
      end

      def process(request)
        begin
          @response_factory.response_from(request)
        rescue Exception => e
          @response_factory.response(500)
        end
      end

    end
  end
end
