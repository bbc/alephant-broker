require 'crimp'
require 'alephant/logger'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'
require 'alephant/broker/cache'

module Alephant
  module Broker
    class Component
      attr_reader :id, :batch_id, :options, :content, :content_type, :cached,
                  :load_strategy

      def initialize(id, batch_id, load_strategy, options)
        @id       = id
        @batch_id = batch_id
        @options  = symbolize(options || {})
        @load_strategy = load_strategy
      end

      def opts_hash
        @opts_hash ||= Crimp.signature(options)
      end

      def load
        load_strategy.load self
      end

      private

      def symbolize(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end

      def key
        batch_id.nil? ? component_key : renderer_key
      end

      def component_key
        "#{id}/#{opts_hash}"
      end

      def renderer_key
        "#{batch_id}/#{opts_hash}"
      end
    end
  end
end
