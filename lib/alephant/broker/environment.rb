require 'json'
require 'alephant/logger'

module Alephant
  module Broker
    class Environment
      include Logger
      attr_reader :settings

      def initialize(env)
        @settings = env
      end

      def method
        settings['REQUEST_METHOD']
      end

      def post?
        settings['REQUEST_METHOD'] == 'POST'
      end

      def get?
        settings['REQUEST_METHOD'] == 'GET'
      end

      def query
        settings['QUERY_STRING'] || ""
      end

      def path
        settings['PATH_INFO']
      end

      def data
        parse(rack_input) if post?
      end

      def options
        convert_keys Rack::Utils.parse_nested_query(query)
      end

      private

      def convert_keys(hash)
        Hash[ hash.map { |k, v| [k.to_sym, v] } ]
      end

      def rack_input
        (settings['rack.input'].read).tap { settings['rack.input'].rewind }
      end

      def parse(json)
        begin
          JSON.parse(json)
        rescue JSON::ParserError => e
          logger.warn("Broker.environment#data: ParserError")
          nil
        end
      end
    end
  end
end
