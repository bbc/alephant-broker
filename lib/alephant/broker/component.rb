require 'alephant/logger'
require 'alephant/broker/cache'
require 'alephant/broker/component/loader'

module Alephant::Broker
  module Component

    def self.create(id, batch_id, options)
      cache_client = Cache::Client.new
      adapter = Loader::Static.new(cache_client)

      Component.new(id, batch_id, options, loader)
    end

    class Component
      include Logger

      attr_reader :id, :batch_id, :options, :content, :cached, :loader

      def initialize(id, batch_id, options, loader)
        @loader    = loader
        @id        = id
        @batch_id  = batch_id
        @cache     = Cache::Client.new
        @options   = symbolize(options || {})
        @cached    = true
      end

      def load
        response ||= cache.get(cache_key) do
          @cached = false
          loader.load(id, batch_id, opts_hash)
        end

        @version   = response[:version]
        @content   = response[:content]
      end

      private

      def cache_key
        @cache_key ||= "#{id}/#{opts_hash}/#{version}"
      end

      def symbolize(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end

    end
  end
end

