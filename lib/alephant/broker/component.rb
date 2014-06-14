require 'crimp'
require 'alephant/logger'
require 'alephant/cache'
require 'alephant/lookup'
require 'alephant/broker/errors/invalid_cache_key'
require 'alephant/sequencer'
require 'alephant/broker/cache'


module Alephant
  module Broker
    class Component
      class Adapter
        attr_reader :cache

        def initialize(cache_client)
          @cache = cache_client
        end

        def load(id, batch_id, opts_hash)
          {
            :content   => s3.get(s3_path_for(id, options, version),
            :opts_hash => opts_hash,
            :version   => version
          }
        end

        def version
          @version ||= sequencer.get_last_seen
        end

        def s3
          @s3_cache ||= Alephant::Cache.new(
            Broker.config[:s3_bucket_id],
            Broker.config[:s3_object_path]
          )
        end

        def s3_path_for(id,options,version)
          lookup.read(id, options, version).tap do |lookup_object|
            raise InvalidCacheKey if lookup_object.location.nil?
          end.location unless version.nil?
        end

        def lookup
          @lookup ||= Alephant::Lookup.create(Broker.config[:lookup_table_name])
        end

        def key
          batch_id.nil? ? component_key : renderer_key
        end

        def component_key
          "#{id}/#{opts_hash}"
        end

        def renderer_key
          "#{batch_id}/#{opts_hash}"
        end

        def sequencer
          @sequencer ||= Alephant::Sequencer.create(Broker.config[:sequencer_table_name], key)
        end
      end
    end
  end
end

module Alephant
  module Broker

    class Component
      include Logger

      attr_reader :id, :batch_id, :options, :content, :cached, :adaptor

      def initialize(id, batch_id, options, adaptor)
        @adaptor   = adaptor
        @id        = id
        @batch_id  = batch_id
        @cache     = Cache::Client.new
        @options   = symbolize(options || {})
        @opts_hash = Crimp.signature(options)
        @cached    = true
      end

      def load
        response ||= cache.get(cache_key) do
          @cached = false
          adaptor.load(id, batch_id, opts_hash)
        end

        @version   = response[:version]
        @content   = response[:content]
      end

      private

      def cache_key
        @cache_key ||= "#{id}/#{opts_hash}/#{version}"
      end

      def symbolize(hash)
        Hash[hash.map { |k,v| [k.to_sym, v] }]
      end

    end
  end
end
