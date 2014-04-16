require 'alephant/broker/request/asset'
require 'alephant/broker/request/batch'
require 'alephant/broker/request/notfound'
require 'alephant/broker/request/status'


module Alephant::Broker::Request
  class Factory

    def self.request_type_from(env)
      env.path.split('/')[1]
    end

    def self.request_for(env)
      case request_type_from(env)
      when 'component'
        Asset.new(env)
      when 'components'
        Batch.new(env)
      when 'status'
        Status.new
      else
        NotFound.new
      end
    end
  end
end

