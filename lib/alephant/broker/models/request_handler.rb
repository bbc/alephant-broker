require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/models/response'
require 'alephant/broker/models/request'

module Alephant
  module Broker
    class RequestHandler

      def initialize(config)
        @config = config
        @cache = Cache.new(config[:bucket_id], config[:path])
      end

      def process(env)
        begin
          request = Request.new(env)
          response = Response.new

          case request.type
          when :status
            response.content = 'ok'
          when :asset
            lookup = Alephant::Lookup.create(@config[:lookup_table_name], request.component_id)

            opts = {}
            opts[:variant] = request.variant if request.variant?

            cache_id = lookup.read(opts)
            raise 'Cache key not found based on options' if cache_id.nil?

            response.content_type = request.content_type
            response.content = @cache.get(cache_id)
          else
            response.status = 404
          end
        rescue AWS::S3::Errors::NoSuchKey
          response.status = 404
        rescue Exception => e
          response.status = 500
          response.content = "#{e.message}"
        end

        response
      end

    end
  end
end
