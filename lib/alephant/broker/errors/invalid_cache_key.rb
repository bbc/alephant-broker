module Alephant
  module Broker
    class InvalidCacheKey < Exception
      def initialize
        super "Cache key not found based on component_id and options combination"
      end
    end
  end
end
