require "json"
require "alephant/logger"
require "rack"

module Alephant
  module Broker
    class Environment
      include Logger
      attr_reader :settings

      def initialize(env)
        @settings = env
      end

      def method
        settings["REQUEST_METHOD"]
      end

      def post?
        settings["REQUEST_METHOD"] == "POST"
      end

      def get?
        settings["REQUEST_METHOD"] == "GET"
      end

      def options?
        settings["REQUEST_METHOD"] == "OPTIONS"
      end

      def query
        settings["QUERY_STRING"] || ""
      end

      def path
        settings["PATH_INFO"]
      end

      def if_none_match
        settings["HTTP_IF_NONE_MATCH"]
      end

      def if_modified_since
        settings["HTTP_IF_MODIFIED_SINCE"]
      end

      def data
        parse(rack_input) if post?
      end

      def options
        Rack::Utils.parse_nested_query query
      end

      private

      def rack_input
        settings["rack.input"].read.tap { settings["rack.input"].rewind }
      end

      def parse(json)
        ::JSON.parse(json)
      rescue ::JSON::ParserError => e
        logger.warn "Broker.environment#data: ParserError"
        logger.metric "JSONParserError"
        nil
      end
    end
  end
end
