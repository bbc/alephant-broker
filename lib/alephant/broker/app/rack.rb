$: << File.dirname(__FILE__)

require 'alephant/broker/app'
require 'alephant/broker/call_environment'

module Alephant
  module Broker
    class RackApplication < Application

      def call(env)
        RequestStore.store[:env] ||= CallEnvironment.new(env)
        response = handle
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
