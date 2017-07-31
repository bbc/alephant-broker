require 'alephant/logger'

module Alephant
  module Broker
    module Response
      class Dials < Base
        include Logger

        def initialize
          super(status, 'application/json')
        end

        def setup
          @content = File.read(dials_file)
          log
        end

        def dials_file
          '/etc/cosmos-dials/dials.json'
        end

        def dials_file_exists?
          File.exist?(dials_file)
        end

        def status
          dials_file_exists? ?
            200 :
            404
        end

        def log
          logger.metric "BrokerResponse#{status}"
          logger.info "Broker: Dials loaded! (#{status})"
        end
      end
    end
  end
end
