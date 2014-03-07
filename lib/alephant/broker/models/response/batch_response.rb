require 'alephant/logger'

module Alephant
  module Broker
    class BatchResponse
      include Logger
      attr_reader :status, :content_type, :content

      def initialize(request, config, env)
        @request      = request
        @config       = config
        @env          = env
        @status       = 200
        @content_type = request.content_type
      end

      def process
        @content = JSON.generate({ "components" => json })
        self
      end

      private

      def json
        get_components.each do |component|
          id      = component['component']
          options = component['variant'] ? { :variant => component['variant'] } : {}

          @request.set_component(id, options)

          component.store('body', AssetResponse.new(@request, @config).content)
          component.delete('variant')
        end
      end

      def get_components
        @request.requested_components.fetch(:components) do |key|
          logger.info("Broker::BatchResponse.process: Received request object but no valid key was found")
          []
        end
      end
    end
  end
end


