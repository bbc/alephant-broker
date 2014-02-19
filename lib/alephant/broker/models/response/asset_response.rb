require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'

module Alephant
  module Broker
    class AssetResponse < Response

      attr_reader :request

      def initialize(request, config)
        @request = request
        @lookup = Alephant::Lookup.create(config[:lookup_table_name], request.component_id)
        super
      end

      def setup
        begin
          content_type = request.content_type
          content = @cache.get cache_id
        rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey
          status = 404
        rescue Exception
          status = 500
        end

      end

      private

      def opts
        opts = {}.tap { |o| o[:variant] = request.variant if request.variant? }
      end

      def cache_id
        @lookup.read(opts).tap { |cache_id| raise InvalidCacheKey if cache_id.nil? }
      end

    end
  end
end


