module Alephant
  module Broker
    class ErrorComponent
      attr_reader :batch_id, :content, :id, :options, :status

      def initialize(meta, status, body = nil)
        @batch_id = meta.batch_id
        @status   = status
        @content  = content_for body
        @id       = meta.id
        @options  = {}
      end

      def content_type
        headers['Content-Type']
      end

      def headers
        {
          'Content-Type' => 'text/plain'
        }
      end

      private

      STATUS_CODE_MAPPING = {
        404 => 'Not found',
        500 => 'Error retrieving content'
      }

      def content_for(body)
        body.nil? ? STATUS_CODE_MAPPING[status]
                  : format_content_for(body)
      end

      def format_content_for(body)
        body.is_a? Exception ? "#{e.message}\n#{e.backtrace.join('\n')}"
                             : body
      end
    end
  end
end
