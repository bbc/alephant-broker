module Alephant
  module Broker
    module Cache
      class NullClient
        def initialize
          @cache = {}
        end

        def get(key)
          data = @cache[key]

          return data if data

          set(key, block.call) if block_given?
        end

        def set(key, value, _ttl = nil)
          @cache[key] = value
        end
      end
    end
  end
end
