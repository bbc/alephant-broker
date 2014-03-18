require 'crimp'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'

module Alephant
  module Broker
    class AssetResponse < Response
      include Logger

      attr_reader :request

      def initialize(request, config)
        @request = request
        @config  = config
        super()
      end

      def setup
        begin
          self.content_type = request.content_type
          self.content = cache.get(s3_path)
        rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey => e
          set_error_for(e, 404)
        rescue Exception => e
          set_error_for(e, 500)
        end
      end

      private

      def cache
        @cache ||= Alephant::Cache.new(config[:bucket_id], config[:path])
      end

      def set_error_for(exception, status)
        logger.info("Broker.assetResponse.set_error_for: #{status} exception raised (#{exception.message})")
        self.status = status
        self.content = exception.message
      end

      def s3_path
        lookup.read(id, request.options, version).tap { |cache_id| raise InvalidCacheKey if cache_id.nil? }
      end

      def lookup
        @lookup ||= Alephant::Lookup.create(config[:lookup_table_name])
      end

      def asset?
        request.type == :asset
      end

      def key
        asset? ? component_key : renderer_key
      end

      def component_key
        "#{component_id}/#{opts_hash}"
      end

      def renderer_key
        "#{renderer_id}/#{opts_hash}"
      end

      def id
        asset? ? component_id : renderer_id
      end

      def component_id
        request.component_id
      end

      def renderer_id
        request.renderer_id
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

      def config
        @config
      end
    end
  end
end
