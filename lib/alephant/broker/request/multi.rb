require 'alephant/logger'
require 'alephant/broker/component'


module Alephant
  module Broker
    module Request
      class Multi
        include Logger

        attr_reader :requests

        def initialize(env)
          logger.debug("Request::Multi#initialize(#{env.settings})")
          @requests = requests_for env
        end

        private

        def requests_for(env)
          env.data['requests'].map do |c|
            case c['type']
            when 'batch'
              #Batch.new
            when 'asset'
              #Asset.new
            end
          end
        end

      end
    end
  end
end

