require 'cgi'

module Alephant
  module Broker
    class ComponentMeta
      attr_reader :id, :raw_options, :batch_id
      attr_accessor :cached

      def initialize(id, batch_id, raw_options)
        @id          = id
        @batch_id    = batch_id
        @raw_options = raw_options
        @cached      = true
      end

      def cache_key
        "#{id}/#{opts_hash}/#{version}"
      end

      def options
        @options ||= raw_options.split('&').reduce({}) do |object, key_pair|
          key, value = key_pair.split('=')
          object.tap { |o| o.store(key.to_sym, CGI.unescape(value)) }
        end
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
