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
        @cache = Cache.new(config[:bucket_id], config[:path])
        super()
      end

      def setup
        begin
          self.content_type = request.content_type
          self.content = @cache.get cache_id
        rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey
          self.status = 404
        rescue Exception => e
          self.status = 500
        end

      end

      private

      def cache_id
        @lookup.read(request.options).tap { |cache_id| raise InvalidCacheKey if cache_id.nil? }
      end

    end
  end
end


