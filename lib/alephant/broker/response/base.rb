require 'alephant/broker/errors/invalid_cache_key'
require 'aws-sdk'
require 'ostruct'

module Alephant
  module Broker
    module Response
      class Base
        attr_reader :content, :headers, :status

        STATUS_CODE_MAPPING = {
          200 => 'ok',
          404 => 'Not found',
          500 => 'Error retrieving content'
        }

        def initialize(status = 200, content_type = "text/html")
          @content = STATUS_CODE_MAPPING[status]
          @headers = { "Content-Type" => content_type }
          @status  = status

          setup
        end

        protected

        def setup; end
      end
    end
  end
end

