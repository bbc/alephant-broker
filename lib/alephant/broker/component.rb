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
      attr_reader :id, :batch_id, :options, :content, :headers, :opts_hash

      def initialize(id, batch_id, content, headers, options, opts_hash)
        @id        = id
        @batch_id  = batch_id
        @options   = symbolize(options || {})
        @headers   = headers
        @content   = content.force_encoding 'UTF-8'
        @opts_hash = opts_hash
      end

      def content_type
        headers['Content-Type']
      end

      private

      def symbolize(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end
    end
  end
end
