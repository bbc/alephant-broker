require 'aws-sdk'

module Alephant
  module Broker
    module Response
      class Base
        attr_accessor :status, :content, :content_type

        STATUS_CODE_MAPPING = {
          200 => 'ok',
          404 => 'Not found',
          500 => 'Error retrieving content'
        }

        def initialize(status = 200, content_type = "text/html")
          @content_type = content_type
          @status  = status
          @content = STATUS_CODE_MAPPING[status]

          setup
        end

        protected

        def setup; end

        def load(component)
          begin
            body   = component.load
            status = 200
          rescue AWS::S3::Errors::NoSuchKey, InvalidCacheKey => e
            body   = "#{error_for(e)}"
            status = 404
          rescue StandardError => e
            body   = "#{error_for(e)}"
            status = 500
          end

          log(component, status, e)

          { 'body' => body, 'status' => status }
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

