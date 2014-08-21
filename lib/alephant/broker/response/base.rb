require 'aws-sdk'
require 'ostruct'

module Alephant
  module Broker
    module Response
      class Base
        attr_reader :headers
        attr_accessor :status, :content, :content_type, :version, :sequence, :cached

        STATUS_CODE_MAPPING = {
          200 => 'ok',
          404 => 'Not found',
          500 => 'Error retrieving content'
        }

        def initialize(status = 200, content_type = "text/html")
          @headers      = {}
          @sequence     = 'not available'
          @version      = Broker.config.fetch('elasticache_cache_version', 'not available').to_s
          @cached       = false
          @content_type = content_type
          @status       = status
          @content      = STATUS_CODE_MAPPING[status]

          setup
        end

        def to_h
          {
            :status       => @status,
            :content      => @content,
            :content_type => @content_type,
            :version      => @version,
            :sequence     => @sequence,
            :cached       => @cached
          }
        end

        protected

        def setup; end

        def load(component)
          begin

            data = OpenStruct.new(:status => 200, :content_type => content_type)
            component.load

            data.content_type = component.content_type
            data.body         = component.content.force_encoding('UTF-8')
          rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey => e
            data.body   = "Not found"
            data.status = 404
          rescue StandardError => e
            data.body   = "#{error_for(e)}"
            data.status = 500
          end

          log(component, data.status, e)
          data.marshal_dump
        end

        def log(c, status, e = nil)
          logger.info("Broker: Component loaded: #{details_for(c)} (#{status}) #{error_for(e)}")
        end

        def details_for(c)
          "#{c.id}/#{c.opts_hash}/#{c.version} #{c.batch_id.nil? ? '' : "batched"} (#{c.options})"
        end

        def error_for(e)
          e.nil? ? nil : "#{e.message}\n#{e.backtrace.join('\n')}"
        end

      end
    end
  end
end

