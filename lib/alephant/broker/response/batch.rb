require 'alephant/logger'
require 'peach'

module Alephant
  module Broker
    module Response
      class Batch < Base
        include Logger

        attr_reader :components, :batch_id

        def initialize(components, batch_id)
          @components = components
          @batch_id   = batch_id

          super(200, 'application/json')
        end

        def setup
          @content = JSON.generate({
            "batch_id" => batch_id,
            "components" => json
          })
        end

        private

        def json
          logger.info("Broker: Batch load started (#{batch_id})")
          result = components.pmap do | component |
            {
              'component' => component.id,
              'options'   => component.options
            }.merge load(component)
          end
          logger.info("Broker: Batch load done (#{batch_id})")

          result
        end

      end
    end
  end
end

