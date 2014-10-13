require "alephant/broker/cache"

module Alephant
  module Broker
    module LoadStrategy
      class S3
        attr_reader :id, :component

        def initialize
          @cache = Cache::Client.new
          @cached = true
        end

        def load(component)
          @component = component
          @content_type = cache_object[:content_type]
          @content      = cache_object[:content]
        rescue
          content_hash  = @cache.set(cache_key, retrieve_object)
          @content_type = content_hash[:content_type]
          @content      = content_hash[:content]
        end

        private 

        def retrieve_object
          @cached = false
          s3.get(s3_path)
        end

        def cache_object
          @cache_object ||= @cache.get(cache_key) { retrieve_object }
        end

        def cache_key
          @cache_key ||= "#{component.id}/#{component.opts_hash}/#{component.version}"
        end

        def s3
          @s3_cache ||= Alephant::Cache.new(
            Broker.config[:s3_bucket_id],
            Broker.config[:s3_object_path]
          )
        end

        def s3_path
          lookup.read(component.id, component.options, component.version).tap do |lookup_object|
            raise InvalidCacheKey if lookup_object.location.nil?
          end.location unless component.version.nil?
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
