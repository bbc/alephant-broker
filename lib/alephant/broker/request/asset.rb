require 'alephant/logger'
require 'alephant/broker/component'
require 'alephant/broker/errors/invalid_asset_id'

module Alephant
  module Broker
    module Request
      class Asset
        include Logger

        attr_accessor :component

        def initialize(env = nil)
          return if env.nil?

          component_id = env.path.split('/')[2] || nil
          options      = env.options

          raise InvalidAssetId.new("No Asset ID specified") if component_id.nil?

          @component = Component.new(component_id, nil, options)
        end

      end
    end
  end
end

