require 'alephant/logger'

require 'alephant/broker/request'
require 'alephant/broker/response'
require 'alephant/broker/request/factory'
require 'alephant/broker/response/factory'

module Alephant
  module Broker
    module Request
      class Handler
        extend Logger

        def self.request_for(env)
          Request::Factory.request_for env
        end

        def self.response_for(request)
          Response::Factory.response_for request
        end

        def self.process(env)
          begin
            response_for request_for(env)
          rescue Exception => e
            logger.info("Broker.requestHandler.process: Exception raised (#{e.message}, #{e.backtrace.join('\n')})")
            Response::Factory.error
          end
        end

      end
    end
  end
end

