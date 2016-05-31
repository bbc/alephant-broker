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
          logger.info "Setting CachedObject content: #{to_h(s3_obj)}"
          @s3_obj = s3_obj
        end

        def update(s3_obj)
          logger.info "Updating CachedObject content: #{to_h(s3_obj)}"
          @s3_obj = s3_obj
        end

        def updated
          time = s3_obj.metadata["head_Last-Modified"]
          Time.parse(time)
        rescue TypeError, ArgumentError
          Time.now
        end

        def ttl
          delta = s3_obj.metadata["ttl"]
          Integer(delta)
        rescue TypeError
          Broker.config[:revalidate_cache_ttl] || DEFAULT_TTL
        end

        def expired?
          (updated + ttl) < Time.now
        end

        def to_h(obj = nil)
          obj_to_serialize = obj || s3_obj

          {
            :content      => obj_to_serialize.read,
            :content_type => obj_to_serialize.content_type,
            :meta         => obj_to_serialize.metadata.to_h
          }
        end
      end
    end
  end
end
