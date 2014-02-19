module Alephant
  module Broker
    class Response
      attr_accessor :content, :content_type
      attr_reader :status

      STATUS_CODE_MAPPING = {
        200 => 'ok',
        404 => 'Not found',
        500 => 'Error retrieving content'
      }

      def initialize(status = 200)
        @content_type = "text/html"
        @status = status
        setup
      end

      def status=(code)
        @status = code
        @content = STATUS_CODE_MAPPING[code]
      end

      def setup; end

    end
  end
end
