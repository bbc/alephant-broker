require 'json'

module Alephant
  module Broker
    module Response
      class Multi < Base

        def initialize(requests)
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
            else
              raise StandardError.new "response type not identified"
            end
          end
        end
      end
    end
  end
end
