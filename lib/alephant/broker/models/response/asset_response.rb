require 'crimp'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'

module Alephant
  module Broker
    class AssetResponse < Response
      include Logger

      attr_reader :request, :opts_hash, :version

      def initialize(request, config)
        @request   = request
        @opts_hash = Crimp.signature request.options
        @lookup    = Alephant::Lookup.create(config[:lookup_table_name])
        @cache     = Cache.new(config[:bucket_id], config[:path])
        @sequencer = Alephant::Sequencer.create(config[:sequencer_table_name, component_key, config[:sequence_id_path])
        @version   = nil # ???
        super()
      end

      def setup
        begin
          self.content_type = request.content_type
          self.content = @cache.get cache_id
        rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey => e
          set_error_for(e, 404)
        rescue Exception => e
          set_error_for(e, 500)
        end
      end

      private

      def set_error_for(exception, status)
        logger.info("Broker.assetResponse.set_error_for: #{status} exception raised (#{exception.message})")
        self.status = status
        self.content = exception.message
      end

      def cache_id
        @lookup.read(request.component_id, request.options, version).tap { |cache_id| raise InvalidCacheKey if cache_id.nil? }
      end

      def component_key
        "#{request.component_id}/#{opts_hash}"
      end
    end
  end
end
