require 'alephant/broker/errors'

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
          rescue Aws::S3::Errors::NoSuchKey, InvalidCacheKey => error
            logger.error(method: "#{self.class}#fetch", error: error)
            logger.metric('S3InvalidCacheKey')
            raise Alephant::Broker::Errors::ContentNotFound
          end

          private

          def s3_path
            lookup_read = lookup.read(component_meta.id, component_meta.options, 1)

            raise InvalidCacheKey if lookup_read.location.nil?

            lookup_read.location
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
