$: << File.dirname(__FILE__)

require 'alephant/broker/app'

module Alephant
  module Broker
    class RackApplication < Application

      def call(env)
        response = handle(
          request_from(env['PATH_INFO'], env['QUERY_STRING'])
        )
        send response
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
