module Alephant
  module Broker
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
