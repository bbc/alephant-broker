require 'crimp'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'

module Alephant
  module Broker
    module Component
      module Loader

        class Static
          attr_reader :cache

          def initialize(cache_client)
            @cache = cache_client
          end

          def load(id, batch_id, options)
            opts_hash  = Crimp.signature(options)
            sequencer  = sequencer_for "#{batch_id || id}/#{opts_hash}"

            version    = sequencer.get_last_seen
            path       = path_for(id, options, version)

            {
              :content   => datastore.get(path),
              :version   => version
            }
          end

          private

          def datastore
            @datastore ||= Alephant::Cache.new(
              Broker.config[:s3_bucket_id],
              Broker.config[:s3_object_path]
            )
          end

          def path_for(id, options, version)
            lookup.read(lookup_key, options, version).tap do |lookup_object|
              raise InvalidCacheKey if lookup_object.location.nil?
            end.location unless version.nil?
          end

          def lookup
            @lookup ||= Alephant::Lookup.create(
              Broker.config[:lookup_table_name]
            )
          end

          def sequencer_for(seq_key)
            @sequencer ||= Alephant::Sequencer.create(
              Broker.config[:sequencer_table_name],
              seq_key
            )
          end
        end
      end
    end
  end
end

