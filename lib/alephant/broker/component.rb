require 'crimp'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'

module Alephant
  module Broker
    class Component
      attr_reader :id, :batch_id, :options, :content

      def initialize(id, batch_id, options)
        @id       = id
        @batch_id = batch_id
        @options  = options
      end

      def load
        @content ||= cache.get(s3_path)
      end

      private

      def cache
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
        @lookup ||= Alephant::Lookup.create(config[:lookup_table_name])
      end

      def key
        request.type == :batch ? renderer_key : component_key
      end

      def component_key
        "#{id}/#{opts_hash}"
      end

      def renderer_key
        "#{renderer_id}/#{opts_hash}"
      end

      def opts_hash
        @opts_hash ||= Crimp.signature(request.options)
      end

      def version
        @version ||= sequencer.get_last_seen
      end

      def sequencer
        @sequencer ||= Alephant::Sequencer.create(config[:sequencer_table_name], key)
      end

    end
  end
end
