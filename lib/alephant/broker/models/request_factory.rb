require 'alephant/broker/models/request/error_request.rb'
require 'alephant/broker/models/request/get_request.rb'
require 'alephant/broker/models/request/notfound_request.rb'
require 'alephant/broker/models/request/post_request.rb'
require 'alephant/broker/models/request/status_request.rb'

module Alephant
  module Broker
    class RequestFactory
      def process(env, type)
        case type
        when :component
          ::Alephant::Broker::GetRequest.new(env)
        when :component_batch
          ::Alephant::Broker::PostRequest.new(env)
        when :status
          ::Alephant::Broker::StatusRequest.new
        when :notfound
          ::Alephant::Broker::NotFoundRequest.new
        when :error
          ::Alephant::Broker::ErrorRequest.new
        end
      end
    end
  end
end
