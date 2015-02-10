require "alephant/broker/load_strategy/s3/base"

module Alephant
  module Broker
    module LoadStrategy
      module S3
        class Archived < Base
          def s3_path(component_meta)
            component_meta.id.tap do |location|
              raise InvalidCacheKey if location.nil?
            end
          end
        end
      end
    end
  end
end
