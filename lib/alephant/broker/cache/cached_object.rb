require "alephant/logger"

module Alephant
  module Broker
    module Cache
      class CachedObject
        include Logger
        attr_reader :ttl, :updated, :content, :content_type

        # FIXME: the `updated` attr should be configured on initialize from S3 meta
        def initialize(content, content_type = "text/plain", ttl = 10)
          @content      = content
          @content_type = content_type
          @ttl          = ttl
          @updated      = Time.now
        end

        def update(c)
          logger.info "Updating cache content #{Time.now}"
          @content       = c[:content]
          @content_type  = c[:content_type]
          @updated       = Time.now
        end

        def expired?
          (updated + ttl) < Time.now
        end
      end
    end
  end
end
