require 'alephant/logger'
require 'alephant/broker/errors/invalid_asset_id'

module Alephant
  module Broker
    module Request
      class Asset
        include Logger

        attr_accessor :component

        def initialize(component_factory, env = nil)
          return if env.nil?
          @component = component_factory.create(
            component_id(env.path),
            nil,
            env.options
          )
        end

        private

        def component_id(path)
          path.split('/')[2] || (raise InvalidAssetId.new 'No Asset ID specified')
        end
      end
    end
  end
end

