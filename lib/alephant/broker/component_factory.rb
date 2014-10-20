require 'alephant/broker/component_meta'
require 'alephant/broker/errors/content_not_found'
require 'alephant/broker/not_found'
require 'alephant/broker/server_error'
require 'alephant/logger'

module Alephant
  module Broker
    class ComponentFactory
      include Logger

      def initialize(load_strategy)
        @load_strategy = load_strategy
      end

      def create(id, batch_id, options)
        component_meta = ComponentMeta.new(id, batch_id, options)
        Component.new(
          component_meta,
          @load_strategy.load(component_meta)
        )
      rescue Alephant::Broker::Errors::ContentNotFound
        logger.warn 'Broker.ComponentFactory.create: Exception raised (ContentNotFound)'
        NotFound.new component_meta
      rescue => e
        logger.warn("Broker.ComponentFactory.create: Exception raised (#{e.message}, #{e.backtrace.join('\n')})")
        ServerError.new(component_meta, e)
      end
    end
  end
end
