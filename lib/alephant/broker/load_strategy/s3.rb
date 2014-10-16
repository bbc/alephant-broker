require "alephant/broker/cache"
require 'alephant/broker/errors/content_not_found'
require 'alephant/broker/errors/invalid_cache_key'

module Alephant
  module Broker
    module LoadStrategy
      class S3
        def load(component_meta)
          create_component(component_meta, cache_object(component_meta))
        rescue
          create_component(
            component_meta,
            cache.set(
              cache_key(component_meta),
              retrieve_object(component_meta)
            )
          )
        end

        private 

        def cache
          @cache ||= Cache::Client.new
        end

        def headers(component_meta, data)
          {
            'Content-Type' => data[:content_type].to_s,
            'X-Sequence'   => sequence(component_meta).to_s,
            'X-Version'    => version.to_s,
            'X-Cached'     => component_meta.cached.to_s
          }
        end

        def create_component(component_meta, data)
          Component.new(
            component_meta.id,
            component_meta.batch_id,
            data[:content], 
            headers(component_meta, data),
            component_meta.options,
            opts_hash(component_meta)
          )
        end

        def version
          Broker.config.fetch(
            'elasticache_cache_version', 'not available'
          ).to_s
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
          cache.get(cache_key component_meta) { retrieve_object }
        end

        def opts_hash(options)
          Crimp.signature component_meta.options
        end

        def component_key(component_meta)
          "#{component_meta.id}/#{opts_hash(component_meta)}"
        end

        def renderer_key(component_meta)
          "#{component_meta.batch_id}/#{opts_hash(component_meta)}"
        end

        def key(component_meta)
          component_meta.batch_id.nil? ? component_key(component_meta)
                                       : renderer_key(component_meta)
        end

        def cache_key(component_meta)
          "#{component_meta.id}/#{opts_hash(component_meta.options)}/#{version}"
        end

        def s3
          @s3 ||= Alephant::Cache.new(
            Broker.config[:s3_bucket_id],
            Broker.config[:s3_object_path]
          )
        end

        def s3_path(component_meta)
          lookup.read(component_meta.id, component_meta.options, sequence(component_meta)).tap do |obj|
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
            Broker.config[:sequencer_table_name], key(component_meta)
          )
        end
      end
    end
  end
end
