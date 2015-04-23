require "alephant/broker/errors/invalid_cache_key"
require "alephant/logger"
require "aws-sdk"
require "ostruct"
require "date"

module Alephant
  module Broker
    module Response
      class Base
        include Logger

        attr_reader :content, :headers, :status

        STATUS_CODE_MAPPING = {
          200 => "ok",
          404 => "Not found",
          500 => "Error retrieving content"
        }

        def initialize(status = 200, content_type = "text/html")
          @content = STATUS_CODE_MAPPING[status]
          @headers = { "Content-Type" => content_type }
          @status  = status

          log_status
          setup
        end

        protected

        def setup; end

        private

        def log_status
          add_no_cache_headers if status !~ /200/
        end

        def add_no_cache_headers
          headers.merge!(
            "Cache-Control" => "no-cache, must-revalidate",
            "Pragma"        => "no-cache",
            "Expires"       => Date.today.prev_year.httpdate
          )
          log
        end

        def log
          logger.metric "BrokerResponse#{status}"
        end
      end
    end
  end
end
