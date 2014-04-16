require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/logger'

module Alephant
  module Broker
    module Response
      class Asset < Base
        include Logger

        attr_reader :component

        def initialize(component)
          @component = component
          super()
        end

        def setup
          begin
            self.content = component.load
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

      end
    end
  end
end

