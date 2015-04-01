require "crimp"
require "alephant/cache"
require "alephant/lookup"
require "alephant/broker/errors/invalid_cache_key"
require "alephant/sequencer"
require "alephant/broker/cache"

module Alephant
  module Broker
    class Component
      attr_reader :id, :batch_id, :options, :content, :opts_hash

      HEADER_PREFIX = "head_"

      def initialize(meta, data)
        @id        = meta.id
        @batch_id  = meta.batch_id
        @options   = symbolize(meta.options || {})
        @content   = data[:content].force_encoding "UTF-8"
        @opts_hash = meta.opts_hash
        @data      = data
        @meta      = meta
      end

      def content_type
        headers["Content-Type"]
      end

      def headers
        {
          "Content-Type" => data[:content_type].to_s
        }
          .merge(data[:headers] || {})
          .merge(meta_data_headers)
      end

      def status
        data[:meta].key?("Status") ? data[:meta]["Status"] : 200
      end

      private

      attr_reader :meta, :data

      def meta_data_headers
        @meta_data_headers ||= data[:meta].reduce({}) do |accum, (k, v)|
          accum.tap do |a|
            a[interpolated_header_key(k)] = v if k.start_with? HEADER_PREFIX
          end
        end
      end

      def interpolated_header_key(key)
        key.gsub(HEADER_PREFIX, "").split("-").map(&:capitalize).join("-")
      end

      def symbolize(hash)
        Hash[hash.map { |k, v| [k.to_sym, v] }]
      end
    end
  end
end
