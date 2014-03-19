require 'alephant/broker/models/request_factory'
require 'alephant/broker/models/response_factory'

module Alephant
  module Broker
    class RequestHandler
      include Logger

      def initialize(config)
        @config = config
      end

      def process
        begin
          response_factory.response_from(request)
        rescue Exception => e
          logger.info("Broker.requestHandler.process: Exception raised (#{e.message})")
          response_factory.response(500)
        end
      end

      private

      def request
        @request ||= RequestFactory.process(request_type)
      end

      def response_factory
        @response_factory ||= ResponseFactory.new(@config)
      end

      def request_type
        case env.request_type
        when 'components'
          :components_batch
        when 'component'
          :component
        when 'status'
          :status
        else
          :notfound
        end
      end

      def env
        @env ||= RequestStore.store[:env]
      end
    end
  end
end
