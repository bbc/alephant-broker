require 'alephant/broker/version'
require 'alephant/broker/request'
require 'alephant/broker/environment'
require 'alephant/broker'

module Alephant
  module Broker

    def self.handle(env)
      Request::Handler.process env
    end

    def self.config
      @@configuration
    end

    def self.config=(c)
      @@configuration = c
    end

    class Application
      def initialize(c = nil)
        Broker.config = c unless c.nil?
      end

      def call(env)
        send response_for(environment_for(env))
      end

      def environment_for(env)
        Environment.new env
      end

      def response_for(call_environment)
        Broker.handle call_environment
      end

      def send(response)
        [
          response.status,
          { "Content-Type" => response.content_type },
          [ response.content.to_s ]
        ]
      end
    end
  end
end
