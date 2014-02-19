require "alephant/broker/version"
require "alephant/broker/models/request_handler"

module Alephant
  module Broker

    def self.handle(request, config = {})
      @@request_handler ||= RequestHandler.new(config)
      @@request_handler.process(request)
    end
  end

end
