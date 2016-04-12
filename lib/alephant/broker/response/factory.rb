require 'alephant/broker/response'

module Alephant
  module Broker
    module Response
      class Factory
        def self.response_for(request, env)
          case request
          when Request::Asset
            Asset.new(request.component, env)
          when Request::Batch
            Batch.new(request.components, request.batch_id, env)
          when Request::Status
            Status.new
          else
            NotFound.new
          end
        end

        def self.error
          ServerError.new
        end

        def self.not_found
          NotFound.new
        end
      end
    end
  end
end

