require 'alephant/broker/component'
require 'alephant/broker/component/loader/static'

module Alephant::Broker
  module Component::Loader
    class Base

      def load
        raise NotImplementedError.new('You must implement a load method')
      end

    end
  end
end

