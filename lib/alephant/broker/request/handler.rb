require "alephant/logger"

require "alephant/broker/request"
require "alephant/broker/response"
require "alephant/broker/request/factory"
require "alephant/broker/response/factory"
require "alephant/broker/errors/content_not_found"

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
          response_for request_for(load_strategy, env)
        end
      end
    end
  end
end
