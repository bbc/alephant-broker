require 'alephant/broker/component_meta'

module Alephant
  module Broker
    class ComponentFactory
      def initialize(load_strategy)
        @load_strategy = load_strategy
      end

      def create(id, batch_id, options)
        component_meta = ComponentMeta.new(id, batch_id, options)
        @load_strategy.load(component_meta)
      end
    end
  end
end
