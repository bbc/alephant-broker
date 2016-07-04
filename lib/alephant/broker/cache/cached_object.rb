require 'alephant/logger'
require 'time'

module Alephant
  module Broker
    module Cache
      class CachedObject
        include Logger
        attr_reader :s3_obj

        DEFAULT_TTL = 10

        def initialize(s3_obj)
          logger.info(event: 'SettingCachedObject', content: s3_obj)
          @s3_obj = s3_obj
        end

        def update(s3_obj)
          logger.info(event: 'UpdatingCachedObject', old_content: @s3_obj, new_content: s3_obj)
          @s3_obj = s3_obj
        end

        def updated
          time = metadata['head_Last-Modified']
          Time.parse(time)
        rescue TypeError, ArgumentError
          Time.now
        end

        def ttl
          delta = metadata['ttl']
          Integer(delta)
        rescue TypeError
          Broker.config[:revalidate_cache_ttl] || DEFAULT_TTL
        end

        def expired?
          (updated + Integer(ttl)) < Time.now
        end

        def to_h(obj = nil)
          obj || s3_obj
        end

        private

        def metadata
          s3_obj.fetch(:meta, {})
        end
      end
    end
  end
end
