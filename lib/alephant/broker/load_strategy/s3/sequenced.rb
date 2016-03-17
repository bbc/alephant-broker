require "alephant/broker/load_strategy/s3/base"

module Alephant
  module Broker
    module LoadStrategy
      module S3
        class Sequenced < Base
          def sequence(component_meta)
            sequencer.get_last_seen component_meta.key
          end

          def s3_path(component_meta)
            lookup.read(
              component_meta.id,
              component_meta.options,
              sequence(component_meta)
            ).tap do |obj|
              fail InvalidCacheKey if obj.location.nil?
            end.location unless sequence(component_meta).nil?
          end

          def sequencer
            @sequencer ||= Alephant::Sequencer.create(
              Broker.config[:sequencer_table_name],
              {
                :config => Broker.config
              }
            )
          end

          def cache_key(component_meta)
            "#{super(component_meta)}/#{sequence(component_meta)}"
          end

          def headers(component_meta)
            {
              "X-Sequence" => sequence(component_meta).to_s
            }.merge(super(component_meta))
          end
        end
      end
    end
  end
end
