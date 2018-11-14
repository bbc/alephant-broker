require 'alephant/logger'
require 'time'

module Alephant
  module Broker
    module Cache
      class CachedObject
        include Logger
        attr_reader :s3_obj

        DEFAULT_TTL = 10

        def initialize(obj)
          logger.info(event:   'SettingCachedObject',
                      content: obj,
                      method:  "#{self.class}#initialize")
          @s3_obj = obj
        end

        def update(obj)
          logger.info(event:       'UpdatingCachedObject',
                      old_content: @s3_obj,
                      new_content: obj,
                      method:      "#{self.class}#update")
          @s3_obj = obj
        end

        def updated
          time = metadata[:'head_Last-Modified']
          Time.parse(time)
        rescue TypeError, ArgumentError => error
          logger.error(event: 'updateError', method: "#{self.class}#updated", error: error)
          Time.now
        end

        def ttl
          Integer(metadata[:ttl] || metadata['ttl'])
        rescue TypeError => error
          logger.error(event: 'ttlError', method: "#{self.class}#ttl", error: error)
          Integer(Broker.config[:revalidate_cache_ttl] || DEFAULT_TTL)
        end

        def expired?
          result = (updated + ttl) < Time.now

          logger.info(event:            'Expired?',
                      updated:          updated,
                      ttl:              ttl,
                      updated_plus_ttl: (updated + ttl),
                      now:              Time.now,
                      result:           result,
                      method:           "#{self.class}#expired?")

          result
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
