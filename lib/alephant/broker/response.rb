module Alephant
  module Broker
    module Response
      require 'alephant/broker/response/base'
      require 'alephant/broker/response/asset'
      require 'alephant/broker/response/batch'
      require 'alephant/broker/response/multi'
      require 'alephant/broker/response/factory'

      class NotFound < Base
        def initialize; super(404) end
      end

      class Status < Base
        def initialize; super(200) end
      end

      class ServerError < Base
        def initialize; super(500) end
      end
    end
  end
end

