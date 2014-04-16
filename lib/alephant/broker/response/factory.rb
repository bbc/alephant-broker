require 'alephant/broker/response'

module Alephant::Broker::Response
  class Factory
    def self.response_for(request)
      case request
      when Request::Asset
        Asset.new(request.component)
      when Request::Batch
        Batch.new(request.components, request.batch_id)
      when Request::Status
        Status.new
      else
        NotFound.new
      end
    end
  end
end

