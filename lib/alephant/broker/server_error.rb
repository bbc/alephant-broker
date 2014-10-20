module Alephant
  module Broker
    class ServerError
      attr_reader :batch_id, :content, :id, :options, :status

      def initialize(meta, e)
        @batch_id = meta.batch_id
        @content  = error_for e
        @id       = meta.id
        @options  = {}
        @status   = 500
      end

      def content_type
        headers['Content-Type']
      end

      def headers
        {
          'Content-Type' => 'application/json'
        }
      end

      private

      def error_for(e)
        e && e.is_a?(Exception) ? "#{e.message}\n#{e.backtrace.join('\n')}"
                                : "Error retrieving content"
      end
    end
  end
end
