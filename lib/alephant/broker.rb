require "alephant/broker/version"
require "alephant/broker/models/request_handler"

module Alephant
  module Broker

    def self.handle(env, config = {})
      @@request_handler ||= RequestHandler.new(config)
      @@request_handler.process(env)
    end
  end

end
