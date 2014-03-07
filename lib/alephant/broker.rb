require "alephant/broker/version"
require "alephant/broker/models/request_handler"

module Alephant
  module Broker

    def self.handle(config = {})
      RequestHandler.new(config).process
    end
  end

end
