require "alephant/broker/cache"
require "alephant/broker/errors/content_not_found"
require "alephant/broker/errors/invalid_cache_key"
require "alephant/logger"

module Alephant
  module Broker
    module LoadStrategy
      module S3
        class Base
          include Logger
          attr_accessor :cached

          def initialize
            @cached = true
          end

          def load(component_meta)
            add_s3_headers(
              cache_object(component_meta),
              component_meta
            )
          rescue
            logger.metric(
              "S3CacheMiss",
              opts[:dimensions].merge(:function => "load")
            )
            add_s3_headers(
              cache.set(
                cache_key(component_meta),
                retrieve_object(component_meta)
              ),
              component_meta
            )
          end

          protected

          def headers(component_meta)
            Hash.new
          end

          def cache_key(component_meta)
            component_meta.component_key
          end

          private

          def opts
            {
              :dimensions => {
                :module   => "AlephantBrokerLoadStrategyS3",
                :class    => "Base"
              }
            }
          end

          def s3_path(component_meta)
            fail NotImplementedError
          end

          def add_s3_headers(component_data, component_meta)
            component_data.merge(
              :headers => headers(component_meta)
            )
          end

          def cache
            @cache ||= Cache::Client.new
          end

          def retrieve_object(component_meta)
            cached = false
            s3.get s3_path(component_meta)
          rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey
            logger.metric(
              "S3InvalidCacheKey",
              opts[:dimensions].merge(:function => "retrieve_object")
            )
            raise Alephant::Broker::Errors::ContentNotFound
          end

          def cache_object(component_meta)
            cache.get cache_key(component_meta) do
              retrieve_object component_meta
            end
          end

          def s3
            @s3 ||= Alephant::Cache.new(
              Broker.config[:s3_bucket_id],
              Broker.config[:s3_object_path]
            )
          end

          def lookup
            @lookup ||= Alephant::Lookup.create(
              Broker.config[:lookup_table_name]
            )
          end

          def headers(component_meta)
            {
              'X-Cache-Version'    => Broker.config['elasticache_cache_version'].to_s,
              'X-Cached'           => cached.to_s
            }
          end
        end
      end
    end
  end
end
