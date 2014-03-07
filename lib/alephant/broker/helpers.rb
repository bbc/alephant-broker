module Alephant
  module Broker
    module Helpers
      DEFAULT_EXTENSION = :html

      def options_from(query_string)
        query_string.split('&').reduce({}) do |object, key_pair|
          key, value = key_pair.split('=')
          object.tap { |o| o.store(key.to_sym, value) }
        end
      end

      def get_type_from(request_parts)
        request_parts[1]
      end

      def get_extension_for(path)
        path.split('.')[1] ? path.split('.')[1].to_sym : DEFAULT_EXTENSION
      end

      def get_component_id_from(request_parts)
        (request_parts[2] || '').split('.')[0]
      end
    end
  end
end
