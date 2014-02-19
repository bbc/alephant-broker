$: << File.dirname(__FILE__)

require 'rack'
require 'alephant/broker'
require 'alephant/broker/application'

module Alephant
  module Broker
    class RackApplication < Application

      def call(env)
        response = handle(env)
        send response
      end

      def send(response)
        [
          response.status,
          {"Content-Type" => response.content_type},
          [response.content.to_s]
        ]
      end
    end
  end
end
