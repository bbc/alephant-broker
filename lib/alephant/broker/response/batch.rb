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
          components.pmap do | component |
            {
              'component' => component.id,
              'options'   => symbolize(component.options)
            }.merge load(component)
          end
        end

        def symbolize(hash)
          Hash[hash.map { |k,v| [k.to_sym, v] }]
        end
      end
    end
  end
end

