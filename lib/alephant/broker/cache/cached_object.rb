require "alephant/logger"

module Alephant
  module Broker
    module Cache
      class CachedObject
        include Logger
        attr_reader :ttl, :updated, :content, :validating, :last_validate, :content_type

        VALIDIATE_TIMEOUT = 30

        def initialize(content, content_type = "text/plain", ttl = 10)
          @content      = content
          @ttl          = ttl
          @validating   = false
          @content_type = content_type
          @updated      = Time.now
        end

        def update(c)
          logger.info "Updating cache content #{Time.now}"
          @content       = c[:content]
          @content_type  = c[:content_type]
          @updated       = Time.now
          @validating    = false
          @last_validate = nil
        end

        def now_validating
          @validating    = true
          @last_validate = Time.now
        end

        def validating?
          logger.info "Checking if validated: #{validating} #{last_validate}"
          return false unless validating
          last_validate && ((last_validate + VALIDIATE_TIMEOUT) > Time.now)
        end

        def expired?
          updated && updated + ttl < Time.now
        end
      end
    end
  end
end
