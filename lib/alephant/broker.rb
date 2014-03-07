require "alephant/broker/version"
require "alephant/broker/models/request_handler"

module Alephant
  module Broker

    def self.handle(env, config = {})
      RequestHandler.new(env, config).process
    end
  end

end
