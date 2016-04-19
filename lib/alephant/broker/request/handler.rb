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

        def self.request_for(load_strategy, request_env)
          Request::Factory.request_for(load_strategy, request_env)
        end

        def self.response_for(request, request_env)
          Response::Factory.response_for(request, request_env)
        end

        def self.process(load_strategy, request_env)
          response_for(request_for(load_strategy, request_env), request_env)
        end
      end
    end
  end
end

