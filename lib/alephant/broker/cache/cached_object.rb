require "alephant/logger"
require "time"

module Alephant
  module Broker
    module Cache
      class CachedObject
        include Logger
        attr_reader :s3_obj

        DEFAULT_TTL = 10

        def initialize(s3_obj)
          logger.info "Setting CachedObject content: #{s3_obj.to_h}"
          @s3_obj = s3_obj
        end

        def update(s3_obj)
          logger.info "Updating CachedObject content: #{s3_obj.to_h}"
          @s3_obj = s3_obj
        end

        def to_h
          s3_obj.to_h
        end

        def updated
          time = s3_obj.meta["head_Last-Modified"]
          Time.parse(time)
        rescue TypeError
          Time.now
        end

        def ttl
          delta = s3_obj.meta["ttl"]
          Integer(delta)
        rescue TypeError
          Broker.config[:revalidate_cache_ttl] || DEFAULT_TTL
        end

        def expired?
          (updated + ttl) < Time.now
        end
      end
    end
  end
end
