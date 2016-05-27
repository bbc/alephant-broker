require "alephant/broker/errors"

module Alephant
  module Broker
    module LoadStrategy
      module Revalidate
        class Fetcher
          include Logger

          attr_reader :component_meta

          def initialize(component_meta)
            @component_meta = component_meta
          end

          def fetch
            Alephant::Broker::Cache::CachedObject.new(s3.get(s3_path))
          rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey
            logger.metric "S3InvalidCacheKey"
            raise Alephant::Broker::Errors::ContentNotFound
          end

          private

          def s3_path
            lookup.read(
              component_meta.id,
              component_meta.options,
              batch_id
            ).tap do |obj|
              raise InvalidCacheKey if obj.location.nil?
            end.location
          end

          def batch_id
            "1" # do we care about sequence/batch_id?
          end

          def s3
            @s3 ||= Alephant::Storage.new(
              Broker.config[:s3_bucket_id],
              Broker.config[:s3_object_path]
            )
          end

          def lookup
            @lookup ||= Alephant::Lookup.create(
              Broker.config[:lookup_table_name],
              Broker.config
            )
          end
        end
      end
    end
  end
end
