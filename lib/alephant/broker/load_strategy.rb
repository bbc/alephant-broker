module Alephant
  module Broker
    module LoadStrategy
      require "alephant/broker/load_strategy/http"
      require "alephant/broker/load_strategy/s3/archived"
      require "alephant/broker/load_strategy/s3/sequenced"
      require "alephant/broker/load_strategy/revalidate/strategy"
      require "alephant/broker/load_strategy/revalidate/refresher"
      require "alephant/broker/load_strategy/revalidate/fetcher"
    end
  end
end
