module Alephant
  module Broker
    class Response
      attr_accessor :content, :content_type
      attr_reader :status

      STATUS_CODE_MAPPING = {
        404 => 'Not found',
        500 => 'Error retrieving content'
      }

      def initialize
        @content_type = "text/html"
        @status = 200
      end

      def status=(code)
        @status = code
        @content = STATUS_CODE_MAPPING[code]
      end

    end
  end
end
