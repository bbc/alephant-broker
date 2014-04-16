require 'alephant/logger'
require 'alephant/broker/component'
require 'alephant/broker/errors/invalid_asset_id'

module Alephant::Broker::Request
  class Asset
    include Logger

    attr_reader :component

    def initialize(env)
      logger.info("Request::Asset#initialize(#{env.settings})")

      @component = Component.new(
        component_id_for env.path,
        nil,
        env.options
      )

      logger.info("Request::Asset#initialize: id: #{@component_id}")
      raise InvalidAssetId.new("No Asset ID specified") if @component_id.nil?
    end

    private

    def component_id_for(path)
      path.split('/')[2] || ''
    end

  end
end

