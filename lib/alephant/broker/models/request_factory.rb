require 'alephant/broker/models/request/error_request.rb'
require 'alephant/broker/models/request/get_request.rb'
require 'alephant/broker/models/request/notfound_request.rb'
require 'alephant/broker/models/request/post_request.rb'
require 'alephant/broker/models/request/status_request.rb'

module Alephant
  module Broker
    class RequestFactory
      def process(type)
        case type
        when :component
          GetRequest.new
        when :component_batch
          PostRequest.new
        when :status
          StatusRequest.new
        when :notfound
          NotFoundRequest.new
        when :error
          ErrorRequest.new
        end
      end
    end
  end
end
