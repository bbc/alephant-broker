require "alephant/broker/version"
require "alephant/broker/request"
require "alephant/broker/environment"
require "alephant/broker/application"
require "alephant/broker/cache"
require "alephant/broker/load_strategy"
require "alephant/broker/errors"

module Alephant
  module Broker
    def self.handle(load_strategy, env)
      Request::Handler.process(load_strategy, env)
    end

    def self.config
      @configuration
    end

    def self.config=(c)
      @configuration = c
    end
  end
end
