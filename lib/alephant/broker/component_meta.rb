module Alephant
  module Broker
    class ComponentMeta
      attr_reader :id, :options, :batch_id
      attr_accessor :cached

      def initialize(id, batch_id, options)
        @id = id
        @batch_id = batch_id
        @options = options
        @cached = true
      end
    end
  end
end
