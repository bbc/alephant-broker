require 'alephant/broker/helpers'
require 'alephant/logger'

module Alephant
  module Broker
    class GetRequest
      include ::Alephant::Broker::Helpers
      include Logger
      attr_reader :type, :component_id, :extension, :options, :content_type

      @@extension_mapping = {
        :html => 'text/html',
        :json => 'application/json'
      }

      def initialize(env)
        parse requested_components(env.path, env.query)
      end

      def requested_components(path, query_string)
        # http://localhost:9292/components/england_council_results
        # http://localhost:9292/components/england_council_results.json
        request_parts = path.split('/')

        {
          :type         => get_type_from(request_parts),
          :component_id => get_component_id_from(request_parts),
          :extension    => get_extension_for(path),
          :options      => options_from(query_string)
        }
      end

      def parse(request)
        @type         = :asset
        @component_id = request[:component_id]
        @extension    = request[:extension]
        @options      = request[:options]
        @content_type = @@extension_mapping[@extension.to_sym] || @@extension_mapping[DEFAULT_EXTENSION]

        logger.info("Broker.request: Type: #{@type}, Asset ID: #{@component_id}, Options: #{@options.inspect}")

        raise Errors::InvalidAssetId.new("No Asset ID specified") if @component_id.nil?
      end
    end
  end
end


