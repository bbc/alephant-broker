module Alephant
  module Broker
    class ComponentFactory
      def initialize(load_strategy)
        @load_strategy = load_strategy
      end

      def create(id, batch_id, options)
        @load_strategy.load(id, batch_id, options)
      end
    end
  end
end
