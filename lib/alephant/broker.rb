require 'alephant/broker/version'
require 'alephant/broker/request'
require 'alephant/broker/environment'
require 'alephant/broker'
require 'ostruct'

module Alephant
  module Broker
    @@poll = true

    def self.handle(env)
      Request::Handler.process env
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
      def initialize(c = nil)
        Broker.config = c unless c.nil?
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
        Broker.handle call_environment
      end

      def send(response)
        [
          response.status,
          {
            "Content-Type" => response.content_type,
            "X-Version"    => response.version.to_s,
            "X-Cached"     => response.cached.to_s
          }.merge(response.headers),
          [ response.content.to_s ]
        ]
      end

      private

      def stop_poll_response
        response = OpenStruct.new(
          :status  => 420,
          :content => "Stopped polling",
          :cached  => false,
          :version => 0,
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
