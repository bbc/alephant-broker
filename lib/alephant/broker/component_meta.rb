module Alephant
  module Broker
    class ComponentMeta
      attr_reader :id, :options, :batch_id
      attr_accessor :cached

      def initialize(id, batch_id, options)
        @id          = id
        @batch_id    = batch_id
        @options     = convert_keys(options || {})
        @cached      = true
      end

      def cache_key
        "#{id}/#{opts_hash}/#{version}"
      end

      def version
        Broker.config.fetch(
          'elasticache_cache_version', 'not available'
        ).to_s
      end

      def key
        batch_id.nil? ? component_key : renderer_key
      end

      def opts_hash
        Crimp.signature options
      end

      private

      def convert_keys(hash)
        Hash[ hash.map { |k, v| [k.to_sym, v] } ]
      end

      def component_key
        "#{id}/#{opts_hash}"
      end

      def renderer_key
        "#{batch_id}/#{opts_hash}"
      end

      def headers(data)
        {
          'Content-Type' => data[:content_type].to_s,
          'X-Version'    => version.to_s,
          'X-Cached'     => cached.to_s
        }.merge(data[:headers] || {})
      end
    end
  end
end
