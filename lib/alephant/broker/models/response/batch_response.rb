require 'alephant/logger'

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
        get_components.each do |component|
          id      = component['component']
          options = set_keys_to_symbols component.fetch('options', {})

          @request.set_component(id, options)

          component.store('body', AssetResponse.new(@request, @config).content)
          component.delete('options')
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
    end
  end
end


