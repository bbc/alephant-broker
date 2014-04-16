require 'alephant/broker/request/factory'
require 'alephant/broker/response/factory'

module Alephant::Broker::Request
  class Handler
    include Logger

    def self.request_for(env)
      RequestFactory.request_for env
    end

    def self.response_for(request)
      ResponseFactory.response_for request
    end

    def self.process(env)
      begin
        response_for request_for(env)
      rescue Exception => e
        logger.info("Broker.requestHandler.process: Exception raised (#{e.message})")
        ResponseFactory.response(500)
      end
    end

  end
end

