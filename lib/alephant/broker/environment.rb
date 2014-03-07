module JSON
  def self.parse_nil(data)
    JSON.parse(data) if data && data.length >= 2
  end
end

module Alephant
  module Broker
    class Environment
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
        begin
          JSON.parse_nil(@settings['rack.input'].read).tap { |o| rewind_rack_input_io } if post?
        rescue Exception => e
          logger.info("Broker.environment.data: Exception raised (#{e.message})")
        end
      end

      private

      def rewind_rack_input_io
        @settings['rack.input'].rewind # http://rack.rubyforge.org/doc/SPEC.html
      end
    end
  end
end
