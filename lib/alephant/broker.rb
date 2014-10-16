require 'alephant/broker/version'
require 'alephant/broker/request'
require 'alephant/broker/environment'
require 'alephant/broker'
require 'ostruct'

module Alephant
  module Broker
    @@poll = true

    def self.handle(load_strategy, env)
      Request::Handler.process(load_strategy, env)
    end

    def self.config
      @@configuration
    end

    def self.config=(c)
      @@configuration = c
    end

    def self.poll?
      @@poll
    end

    def self.poll=(state)
      @@poll = state
    end

    class Application
      attr_reader :load_strategy

      def initialize(load_strategy, c = nil)
        Broker.config = c unless c.nil?
        @load_strategy = load_strategy
      end

      def call(env)
        if ::Alephant::Broker.poll?
          send response_for(environment_for(env))
        else
          send stop_poll_response
        end
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

      private

      def stop_poll_response
        response = OpenStruct.new(
          :status   => 420,
          :content  => "Stopped polling",
          :cached   => false,
          :version  => 0,
          :sequence => 0,
          :headers => {
            "Content-Type"   => "plain/text",
            "X-Cached"       => "false",
            "X-Stop-Polling" => "true"
          }
        )
      end
    end
  end
end
