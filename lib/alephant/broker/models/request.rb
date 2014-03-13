require 'alephant/logger'

module Alephant
  module Broker
    class Request
      include Logger
      attr_reader :type

      DEFAULT_EXTENSION = :html

      @@extension_mapping = {
        :html => 'text/html',
        :json => 'application/json'
      }

      def initialize(request_type)
        logger.info("Broker.request: Type: #{request_type}")
        @type = request_type
      end

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
