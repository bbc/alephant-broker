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

        NOT_MODIFIED_STATUS_CODE = 304

        STATUS_CODE_MAPPING = {
          200                      => "ok",
          NOT_MODIFIED_STATUS_CODE => "",
          404                      => "Not found",
          500                      => "Error retrieving content"
        }

        def initialize(status = 200, content_type = "text/html")
          @content = STATUS_CODE_MAPPING[status]
          @headers = {
            "Content-Type"                  => content_type,
            "Access-Control-Allow-Headers"  => "If-None-Match, If-Modified-Since",
            "Access-Control-Allow-Origin"   => "*"
          }
          headers.merge!(Broker.config[:headers]) if Broker.config.has_key?(:headers)
          @status  = status

          add_no_cache_headers if should_add_no_cache_headers?(status)
          add_etag_allow_header if headers.has_key?("ETag")
          setup if status == 200
        end

        protected

        def setup; end

        private

        def should_add_no_cache_headers?(status)
          status != 200 && status != NOT_MODIFIED_STATUS_CODE
        end

        def add_no_cache_headers
          headers.merge!(
            "Cache-Control" => "no-cache, must-revalidate",
            "Pragma"        => "no-cache",
            "Expires"       => Date.today.prev_year.httpdate
          )
          log
        end

        def add_etag_allow_header
          headers.merge!({
            "Access-Control-Expose-Headers" => "ETag"
          })
        end

        def self.component_not_modified(headers, request_env)
          return false unless allow_modified_response_status
          return false if request_env.post?
          return false if request_env.if_modified_since.nil? && request_env.if_none_match.nil?

          last_modified_match = !request_env.if_modified_since.nil? && headers["Last-Modified"] == request_env.if_modified_since
          etag_match          = !request_env.if_none_match.nil? &&
            unquote_etag(headers["ETag"]) == unquote_etag(request_env.if_none_match)

          last_modified_match || etag_match
        end

        def self.unquote_etag(etag)
          etag.to_s.gsub(/\A"|"\Z/, '')
        end

        def self.allow_modified_response_status
          Broker.config[:allow_modified_response_status] || false
        end

        def log
          logger.metric "BrokerNon200Response#{status}"
        end

      end
    end
  end
end
