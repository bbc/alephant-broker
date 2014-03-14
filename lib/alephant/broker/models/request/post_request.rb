require 'alephant/broker/models/request'

module Alephant
  module Broker
    class PostRequest < Request
      attr_reader :type, :component_id, :options, :content_type

      def initialize
        @env = RequestStore.store[:env]
        @content_type = 'application/json'
        super(:batch)
      end

      def components
        @requested_components ||= components_for @env.path
      end

      def set_component(id, options)
        @component_id = id
        @options      = options
      end

      private

      def components_for(path)
        request_parts = path.split('/')

        {
          :batch_id     => batch_id,
          :type         => get_type_from(request_parts),
          :component_id => get_component_id_from(request_parts)
        }.merge! batched
      end

      def batch_id
        @env.data['batch_id']
      end

      def batched
        @env.data['components'].reduce({ :components => [] }) do |obj, component|
          obj.tap { |o| o[:components].push(component) }
        end
      end
    end
  end
end
