require 'alephant/broker/models/response'
require 'alephant/broker/models/response/asset_response'

module Alephant
  module Broker
    class ResponseFactory

      def initialize(config = nil)
        @config = config
      end

      def response_from(request)
          case request.type
          when :asset
            AssetResponse.new(request, @config)
          when :status
            response(200)
          when :notfound
            response(404)
          when :error
            response(500)
          end
      end

      def response(status)
        Response.new(status)
      end

    end
  end
end
