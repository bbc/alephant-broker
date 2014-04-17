require 'crimp'
require 'alephant/logger'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'

module Alephant
  module Broker
    class Component
      include Logger

      attr_reader :id, :batch_id, :options, :content

      def initialize(id, batch_id, options)
        @id       = id
        @batch_id = batch_id
        @options  = options
      end

      def load
        @content ||= cache.get(s3_path)
      end

      def opts_hash
        @opts_hash ||= Crimp.signature(options)
      end

      def version
        @version ||= sequencer.get_last_seen
      end

      private

      def cache
        @cache ||= Alephant::Cache.new(
          Broker.config[:s3_bucket_id],
          Broker.config[:s3_object_path]
        )
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

      def sequencer
        @sequencer ||= Alephant::Sequencer.create(Broker.config[:sequencer_table_name], key)
      end

    end
  end
end
