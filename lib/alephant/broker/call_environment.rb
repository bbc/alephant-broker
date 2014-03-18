require 'json'

module Alephant
  module Broker
    class CallEnvironment
      include Logger
      attr_reader :settings

      def initialize(env)
        @settings = env
      end

      def method
        @settings['REQUEST_METHOD']
      end

      def post?
        @settings['REQUEST_METHOD'] == 'POST'
      end

      def get?
        @settings['REQUEST_METHOD'] == 'GET'
      end

      def query
        @settings['QUERY_STRING']
      end

      def path
        @settings['PATH_INFO']
      end

      def data
        parse(rack_input) if post?
      end

      private

      def rack_input
          (@settings['rack.input'].read).tap { @settings['rack.input'].rewind } # http://rack.rubyforge.org/doc/SPEC.html
      end

      def parse(json)
        begin
          JSON.parse(json)
        rescue JSON::ParserError => e
          logger.info("Broker.environment#data: ParserError")
          nil
        end
      end
    end
  end
end
