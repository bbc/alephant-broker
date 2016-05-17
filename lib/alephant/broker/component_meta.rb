module Alephant
  module Broker
    class ComponentMeta
      attr_reader :id, :options, :batch_id

      def initialize(id, batch_id, options)
        @id          = id
        @batch_id    = batch_id
        @options     = convert_keys(options || {})
      end

      def key
        batch_id.nil? ? component_key : renderer_key
      end

      def opts_hash
        Crimp.signature options
      end

      def component_key
        "#{id}/#{opts_hash}"
      end

      private

      def convert_keys(hash)
        Hash[hash.map { |k, v| [k.to_sym, v] }]
      end

      def renderer_key
        "#{batch_id}/#{opts_hash}"
      end
    end
  end
end
