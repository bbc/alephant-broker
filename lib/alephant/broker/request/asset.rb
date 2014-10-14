require 'alephant/logger'
require 'alephant/broker/component'
require 'alephant/broker/load_strategy/s3'
require 'alephant/broker/errors/invalid_asset_id'

module Alephant
  module Broker
    module Request
      class Asset
        include Logger

        attr_accessor :component

        def initialize(component_factory, env = nil)
          return if env.nil?

          component_id = env.path.split('/')[2] || nil
          options      = env.options

          raise InvalidAssetId.new("No Asset ID specified") if component_id.nil?

          @component = component_factory.create(component_id, nil, options)
        end
      end
    end
  end
end

