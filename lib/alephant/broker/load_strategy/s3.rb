require "alephant/broker/cache"
require 'alephant/broker/errors/content_not_found'
require 'alephant/broker/errors/invalid_cache_key'

module Alephant
  module Broker
    module LoadStrategy
      class S3
        def load(component_meta)
          component_meta.component(
            add_s3_headers(
              cache_object(component_meta),
              component_meta  
            )
          )
        rescue
          component_meta.component(
            add_s3_headers(
              cache.set(
                component_meta.cache_key,
                retrieve_object(component_meta)
              ),
              component_meta
            )
          )
        end

        private 

        def add_s3_headers(component_data, component_meta)
          component_data.merge(
            { headers: headers(component_meta) }
          )
        end

        def cache
          @cache ||= Cache::Client.new
        end

        def headers(component_meta)
          { 'X-Sequence' => sequence(component_meta).to_s }
        end

        def sequence(component_meta)
          sequencer(component_meta).get_last_seen
        end

        def retrieve_object(component_meta)
          component_meta.cached = false
          s3.get s3_path(component_meta)
        rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey
          raise ContentNotFound
        end

        def cache_object(component_meta)
          cache.get(component_meta.cache_key) do
            retrieve_object component_meta
          end
        end

        def s3
          @s3 ||= Alephant::Cache.new(
            Broker.config[:s3_bucket_id],
            Broker.config[:s3_object_path]
          )
        end

        def s3_path(component_meta)
          lookup.read(
            component_meta.id,
            component_meta.options,
            sequence(component_meta)
          ).tap do |obj|
            raise InvalidCacheKey if obj.location.nil?
          end.location unless sequence(component_meta).nil?
        end

        def lookup
          @lookup ||= Alephant::Lookup.create(
            Broker.config[:lookup_table_name]
          )
        end

        def sequencer(component_meta)
          Alephant::Sequencer.create(
            Broker.config[:sequencer_table_name], component_meta.key
          )
        end
      end
    end
  end
end
