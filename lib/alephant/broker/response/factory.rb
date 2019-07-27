require 'alephant/broker/response'

module Alephant
  module Broker
    module Response
      class Factory
        def self.response_for(request, request_env)
          case request
          when Request::Asset
            Asset.new(request.component, request_env)
          when Request::Batch
            Batch.new(request.components, request.batch_id, request_env)
          when Request::Dials
            Dials.new
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
