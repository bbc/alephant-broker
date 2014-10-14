require "alephant/broker/cache"

module Alephant
  module Broker
    module LoadStrategy
      class S3
        attr_reader :id, :component, :cached, :batch_id, :options

        def initialize
          @cache  = Cache::Client.new
          @cached = true
        end

        def load(id, batch_id, options)
          @id, @batch_id, @options = id, batch_id, options
          create_component(cache_object)
        rescue
          create_component(
            @cache.set(cache_key, retrieve_object)
          )
        end

        private 

        def headers(data)
          {
            'Content-Type' => data[:content_type].to_s,
            #'X-Sequence'   => sequence.to_s,
            'X-Version'    => version.to_s,
            'X-Cached'     => cached.to_s
          }
        end

        def create_component(data)
          Component.new(
            id, 
            batch_id, 
            data[:content], 
            headers(data),
            options,
            opts_hash
          )
        end

        def version
          Broker.config.fetch('elasticache_cache_version', 'not available').to_s
        end

        def sequence
          sequencer.get_last_seen
        end

        def retrieve_object
          @cached = false
          s3.get(s3_path)
        end

        def cache_object
          @cache_object ||= @cache.get(cache_key) { retrieve_object }
        end

        def opts_hash
          @opts_hash ||= Crimp.signature(options)
        end

        def component_key
          "#{id}/#{opts_hash}"
        end

        def renderer_key
          "#{batch_id}/#{opts_hash}"
        end

        def key
          batch_id.nil? ? component_key : renderer_key
        end

        def cache_key
          @cache_key ||= "#{id}/#{opts_hash}/#{version}"
        end

        def s3
          @s3_cache ||= Alephant::Cache.new(
            Broker.config[:s3_bucket_id],
            Broker.config[:s3_object_path]
          )
        end

        def s3_path
          lookup.read(id, options, version).tap do |lookup_object|
            raise InvalidCacheKey if lookup_object.location.nil?
          end.location unless version.nil?
        end

        def lookup
          @lookup ||= Alephant::Lookup.create(Broker.config[:lookup_table_name])
        end

        def sequencer
          @sequencer ||= Alephant::Sequencer.create(Broker.config[:sequencer_table_name], key)
        end
      end
    end
  end
end
