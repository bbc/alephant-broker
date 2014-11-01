require 'alephant/logger'
require 'pmap'

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
            'batch_id' => batch_id,
            'components' => json
          })
        end

        private

        def json
          logger.info "Broker: Batch load started (#{batch_id})"
          result = components.pmap do |component|
	    component.load
            {
              'component'    => component.id,
              'options'      => component.options,
              'status'       => component.status,
              'content_type' => component.content_type,
              'body'         => component.content
            }
          end
          logger.info "Broker: Batch load done (#{batch_id})"

          result
        end

      end
    end
  end
end

