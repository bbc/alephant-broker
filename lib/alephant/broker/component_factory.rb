require 'alephant/broker/component_meta'
require 'alephant/broker/errors/content_not_found'
require 'alephant/broker/error_component'
require 'alephant/logger'

module Alephant
  module Broker
    class ComponentFactory
      include Logger

      def initialize(load_strategy)
        @load_strategy = load_strategy
      end

      def create(id, batch_id, raw_options)
        component_meta = ComponentMeta.new(id, batch_id, raw_options)
        Component.new(
          component_meta,
          @load_strategy.load(component_meta)
        )
      rescue Alephant::Broker::Errors::ContentNotFound => e
        logger.warn 'Broker.ComponentFactory.create: Exception raised (ContentNotFound)'
        ErrorComponent.new(component_meta, 404, e)
      rescue => e
        logger.warn("Broker.ComponentFactory.create: Exception raised (#{e.message}, #{e.backtrace.join('\n')})")
        ErrorComponent.new(component_meta, 500, e)
      end
    end
  end
end
