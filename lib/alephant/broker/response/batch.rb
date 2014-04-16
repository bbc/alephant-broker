require 'alephant/logger'
require 'peach'

module Alephant
  module Broker
    class BatchResponse
      include Logger

      attr_reader :components, :batch_id

      def initialize(components, batch_id)
        @components = components
        @batch_id   = batch_id

        super(200, 'application/json')
      end

      def setup
        @content = JSON.generate({
          "batch_id" => batch_id,
          "components" => json
        })
      end

      private

      def json
        components.pmap do | component |
          begin
            body   = component.load
            status = 200
          rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey => e
            status = 404
          rescue Exception => e
            status = 500
          end

          {
            'component' => component.id
            'options'   => symbolize(component.options)
            'body'      => body
            'status'    => status
          }
        end
      end

      def symbolize(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end
    end
  end
end

