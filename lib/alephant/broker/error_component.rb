module Alephant
  module Broker
    class ErrorComponent
      attr_reader :batch_id, :content, :id, :options, :status

      def initialize(meta, status, exception)
        @batch_id = meta.batch_id
        @status   = status
        @content  = content_for exception
        @id       = meta.id
        @options  = {}
      end

      def content_type
        headers["Content-Type"]
      end

      def headers
        {
          "Content-Type" => "text/plain"
        }
      end

      private

      def content_for(exception)
        exception.message.to_s.tap do |msg|
          msg << "\n#{exception.backtrace.join('\n')}" if debug?
        end
      end

      def debug?
        Broker.config.fetch("debug", false)
      end
    end
  end
end
