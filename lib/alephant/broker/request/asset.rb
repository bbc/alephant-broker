require 'alephant/logger'
require 'alephant/broker/component'
require 'alephant/broker/errors/invalid_asset_id'

module Alephant
  module Broker
    module Request
      class Asset
        include Logger

        attr_reader :component

        def initialize(env)
          logger.debug("Request::Asset#initialize(#{env.settings})")
          component_id = component_id_for env.path

          @component = Component.new(
            component_id,
            nil,
            env.options
          )

          logger.debug("Request::Asset#initialize: id: #{component_id}")
          raise InvalidAssetId.new("No Asset ID specified") if component_id.nil?
        end

        private

        def component_id_for(path)
          path.split('/')[2] || nil
        end

      end
    end
  end
end

