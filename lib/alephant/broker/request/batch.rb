require 'alephant/logger'
require 'alephant/broker/component'


module Alephant::Broker::Request
  class Batch
    include Logger

    attr_reader :batch_id, :components

    def initialize(env)
      logger.info("Request::Batch#initialize(#{env.settings})")

      @batch_id   = env.data['batch_id']
      @components = components_for env

      logger.info("Request::Batch#initialize: id: #{@batch_id}")
    end

    private

    def components_for(env)
      env.data['components'].map do |c|
        Component.new(
          c[:component],
          batch_id,
          c[:options]
        )
      end
    end

  end
end

