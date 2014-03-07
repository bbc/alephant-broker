module Alephant
  module Broker
    class PostRequest
      include ::Alephant::Broker::Helpers
      attr_reader :type, :component_id, :options, :content_type

      def initialize
        @env = RequestStore.store[:env]
        @type = :batch
        @content_type = 'application/json'
      end

      def requested_components
        requested_components_for @env.path
      end

      def set_component(id, options)
        @component_id = id
        @options      = options
      end

      private

      def requested_components_for(path)
        # http://localhost:9292/components/batch (default to JSON)
        request_parts = path.split('/')

        {
          :type         => get_type_from(request_parts),
          :component_id => get_component_id_from(request_parts)
        }.merge! batched
      end

      def batched
        @env.data['components'].reduce({ :components => [] }) do |obj, component|
          obj.tap { |o| o[:components].push(component) }
        end
      end
    end
  end
end
