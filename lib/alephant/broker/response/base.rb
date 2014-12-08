require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/logger'
require 'aws-sdk'
require 'ostruct'

module Alephant
  module Broker
    module Response
      class Base
        include Logger

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

          log if status !~ /200/

          setup
        end

        protected

        def setup; end

        private

        def log
          logger.metric({:name => "BrokerResponse#{status}", :unit => "Count", :value => 1})
        end
      end
    end
  end
end

