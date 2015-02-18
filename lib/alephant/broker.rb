require "alephant/broker/version"
require "alephant/broker/request"
require "alephant/broker/environment"
require "alephant/broker"

module Alephant
  module Broker

    def self.handle(load_strategy, env)
      Request::Handler.process(load_strategy, env)
    end

    def self.config
      @@configuration
    end

    def self.config=(c)
      @@configuration = c
    end

    class Application
      attr_reader :load_strategy

      def initialize(load_strategy, c = nil)
        Broker.config = c unless c.nil?
        @load_strategy = load_strategy
      end

      def call(env)
        send response_for(environment_for(env))
      end

      def environment_for(env)
        Environment.new env
      end

      def response_for(call_environment)
        Broker.handle(load_strategy, call_environment)
      end

      def send(response)
        [
          response.status,
          response.headers,
          [
            response.content.to_s
          ]
        ]
      end
    end
  end
end
