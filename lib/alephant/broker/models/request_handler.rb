require 'alephant/broker/models/request_factory'
require 'alephant/broker/models/response_factory'

module Alephant
  module Broker
    class RequestHandler
      include Logger

      def initialize(env, config)
        @env = env
        @request = RequestFactory.new.process(env, request_type)
        @response_factory = ResponseFactory.new(config)
      end

      def process
        begin
          @response_factory.response_from(@request)
        rescue Exception => e
          logger.info("Broker.requestHandler.process: Exception raised (#{e.message})")
          @response_factory.response(500)
        end
      end

      private

      def request_type
        case @env.path.split('/')[1]
        when 'components'
          component_type
        when 'status'
          :status
        # how do we determine notfound or error status?
        end
      end

      def component_type
        case @env.method
        when 'POST'
          :component_batch
        when 'GET'
          :component
        end
      end
    end
  end
end
