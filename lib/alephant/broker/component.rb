require 'crimp'
require 'alephant/logger'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'

module Alephant
  module Broker

    class ElastiCache
      def initialize
        @elasticache = Dalli::ElastiCache.new(config_endpoint, dalli_options={})
        @client = @elasticache.client
      end

      def config_endpoint
        'location:12111'
      end

      def dalli_options
        {
          :expires_in => 5
        }
      end

      def get(key, &block)
        (result = @client.get(key)) ? result : call_through(key, block)
      end

      def call_through(key, &block)
        result = block.call
        cache.set(key, result)

        result
      end
    end

    class Component
      include Logger

      attr_reader :id, :batch_id, :options, :content, :cache_key

      def initialize(id, batch_id, options)
        @id       = id
        @batch_id = batch_id
        @options  = options
        @cache    = ElastiCache.new
      end

      def load
        @content ||= @cache.get(cache_key) do
          s3.get(s3_path)
        end
      end

      private

      def cache_key
        @cache_key ||= "#{id}/#{opts_hash}/#{version}"
      end

      def s3
        @cache ||= Alephant::Cache.new(
          Broker.config[:s3_bucket_id],
          Broker.config[:s3_object_path]
        )
      end

      def set_error_for(exception, status)
        logger.info("Broker.assetResponse.set_error_for: #{status} exception raised (#{exception.message})")
        self.status = status
        self.content = exception.message
      end

      def s3_path
        lookup.read(id, options, version).tap do |lookup_object|
          raise InvalidCacheKey if lookup_object.location.nil?
        end.location unless version.nil?
      end

      def lookup
        @lookup ||= Alephant::Lookup.create(Broker.config[:lookup_table_name])
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

      def opts_hash
        @opts_hash ||= Crimp.signature(options)
      end

      def version
        @version ||= sequencer.get_last_seen
      end

      def sequencer
        @sequencer ||= Alephant::Sequencer.create(Broker.config[:sequencer_table_name], key)
      end

    end
  end
end
