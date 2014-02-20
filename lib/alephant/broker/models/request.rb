require 'cgi'

module Alephant
  module Broker
    class Request
      attr_reader :type, :component_id, :options, :extension, :content_type

      DEFAULT_EXTENSION = :html

      @@extension_mapping = {
        :html => 'text/html',
        :json => 'application/json'
      }

      def initialize(path, querystring)
        request = request_components(path, querystring)
        case request[:type]
        when "component"
          @type = :asset

          @component_id = request[:component_id]
          raise Errors::InvalidAssetId.new("No Asset ID specified") if @component_id.nil?

          @options = request[:options]
          @extension = request[:extension] || DEFAULT_EXTENSION
          @content_type = @@extension_mapping[@extension.to_sym] || @@extension_mapping[DEFAULT_EXTENSION]
        when "status"
          @type = :status
        else
          @type = :notfound
        end
      end

      private

      def request_components(path, query_string)
        request_parts = path.split('/')
        {
          :type         => request_parts[1],
          :component_id => (request_parts[2] || '').split('.')[0],
          :extension    => path.split('.')[1],
          :options      => options_from(query_string)
        }
      end

      def options_from(query_string)
        query_string.split('&').reduce({}) do |object, key_pair|
          key, value = key_pair.split('=')
          object.tap { |o| o.store(key.to_sym, value) }
        end
      end
    end
  end
end
