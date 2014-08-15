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
      include Logger

      attr_reader :id, :batch_id, :options, :content, :content_type, :cached

      def initialize(id, batch_id, options)
        @id       = id
        @batch_id = batch_id
        @cache    = Cache::Client.new
        @options  = symbolize(options || {})
        @cached   = true
      end

      def load
        @content_type = cache_object[:content_type]
        @content      = cache_object[:content]
      rescue
        content_hash  = @cache.set(cache_key, retrieve_object)
        @content_type = content_hash[:content_type]
        @content      = content_hash[:content]
      end

      def opts_hash
        @opts_hash ||= Crimp.signature(options)
      end

      def version
        @version ||= sequencer.get_last_seen
      end

      private

      def cache_object
        @cache_object ||= @cache.get(cache_key) { retrieve_object }
      end

      def retrieve_object
        @cached = false
        s3.get(s3_path)
      end

      def cache_key
        @cache_key ||= [id, opts_hash, version, broker_version].compact.join('/')
      end

      def broker_version
        @broker_version ||= Broker.config.fetch(:application_version, nil)
      end

      def symbolize(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end

      def s3
        @s3_cache ||= Alephant::Cache.new(
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
