module Alephant
  module Broker
    module LoadStrategy
      require "alephant/broker/load_strategy/http"
      require "alephant/broker/load_strategy/s3/archived"
      require "alephant/broker/load_strategy/s3/sequenced"
      require "alephant/broker/load_strategy/revalidate"
    end
  end
end
