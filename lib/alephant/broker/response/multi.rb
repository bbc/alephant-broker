require 'json'

module Alephant
  module Broker
    module Response
      class Multi < Base
        attr_reader :requests

        def initialize(requests)
          @requests = requests

          super()
        end

        def raw_response
          requests.reduce(:responses => []) do |m,request|
            response = Factory.response_for request

            case response
            when Asset
              m[:responses] << {
                :type     => response.class.to_s.downcase,
                :datatype => response.content_type,
                :payload  => {
                  :component_id => response.component.id,
                  :options      => response.component.options,
                  :body         => response.to_h
                }
              }
            when NotFound
              # Do nothing
            else
              raise StandardError.new "response type not identified"
            end
          end
        end

        def setup
          @content_type = 'application/json'
          @content      = JSON.generate(raw_response)
        end
      end
    end
  end
end
