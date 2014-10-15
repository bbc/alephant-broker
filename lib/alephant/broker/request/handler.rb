require 'alephant/logger'

require 'alephant/broker/request'
require 'alephant/broker/response'
require 'alephant/broker/request/factory'
require 'alephant/broker/response/factory'
require 'alephant/broker/errors/content_not_found'

module Alephant
  module Broker
    module Request
      class Handler
        extend Logger

        def self.request_for(load_strategy, env)
          Request::Factory.request_for(load_strategy, env)
        end

        def self.response_for(request)
          Response::Factory.response_for request
        end

        def self.process(load_strategy, env)
          begin
            response_for request_for(load_strategy, env)
          rescue ContentNotFound
            logger.warn 'Broker.requestHandler.process: Exception raised (Content not found)'
            Response::Factory.not_found
          rescue Exception => e
            logger.warn("Broker.requestHandler.process: Exception raised (#{e.message}, #{e.backtrace.join('\n')})")
            Response::Factory.error
          end
        end
      end
    end
  end
end

