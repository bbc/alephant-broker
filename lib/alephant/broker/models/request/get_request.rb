require 'alephant/broker/errors/invalid_asset_id'
require 'alephant/broker/models/request'

module Alephant
  module Broker
    class GetRequest < Request
      attr_reader :type, :component_id, :extension, :options, :content_type

      def initialize
        super(:asset)
        env = RequestStore.store[:env]
        parse requested_components(env.path, env.query)
      end

      def requested_components(path, query_string)
        request_parts = path.split('/')

        {
          :type         => get_type_from(request_parts),
          :component_id => get_component_id_from(request_parts),
          :extension    => get_extension_for(path),
          :options      => options_from(query_string)
        }
      end

      def parse(request)
        @component_id = request[:component_id]
        @extension    = request[:extension]
        @options      = request[:options]
        @content_type = @@extension_mapping[@extension.to_sym] || @@extension_mapping[DEFAULT_EXTENSION]

        logger.info("Broker.request: Type: #{@type}, Asset ID: #{@component_id}, Options: #{@options.inspect}")

        raise InvalidAssetId.new("No Asset ID specified") if @component_id.nil?
      end
    end
  end
end
