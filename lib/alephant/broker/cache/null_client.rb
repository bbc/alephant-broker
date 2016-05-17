module Alephant
  module Broker
    module Cache
      class NullClient
        def get(_key)
          yield
        end

        def set(_key, value, _ttl = nil)
          value
        end
      end
    end
  end
end
