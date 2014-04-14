require 'alephant/logger'
require 'peach'

module Alephant
  module Broker
    class BatchResponse
      include Logger
      attr_reader :status, :content_type, :content

      def initialize(request, config)
        @request      = request
        @config       = config
        @status       = 200
        @content_type = request.content_type
      end

      def process
        @content = JSON.generate({ "batch_id" => batch_id, "components" => json })
        self
      end

      private

      def json
        get_components.peach do |component|
          thread_local_request = @request.clone

          id      = component['component']
          options = set_keys_to_symbols component.fetch('options', {})

          thread_local_request.set_component(id, options)

          asset = AssetResponse.new(thread_local_request, @config)
          component.store('status', asset.status)
          component.store('body', asset.content) if valid_status_for asset
        end
      end

      def set_keys_to_symbols(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end

      def batch_id
        @request.components.fetch(:batch_id)
      end

      def get_components
        @request.components.fetch(:components) do |key|
          logger.info("Broker::BatchResponse.process: Received request object but no valid key was found")
          []
        end
      end

      def valid_status_for(asset)
        asset.status == 200
      end
    end
  end
end


