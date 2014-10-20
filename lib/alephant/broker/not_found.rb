module Alephant
  module Broker
    class NotFound
      attr_reader :batch_id, :content, :id, :options, :status

      def initialize(meta)
        @batch_id = meta.batch_id
        @content  = 'Not found'
        @id       = meta.id
        @options  = {}
        @status   = 404
      end

      def content_type
        headers['Content-Type']
      end

      def headers
        {
          'Content-Type' => 'application/json'
        }
      end
    end
  end
end
