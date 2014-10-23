module Alephant
  module Broker
    module Errors
      class ContentNotFound < StandardError
        def message
          'Not Found'
        end
      end
    end
  end
end
