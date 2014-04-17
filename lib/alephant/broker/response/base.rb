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
            body   = "#{e.message}"
            status = 404
          rescue StandardError => e
            body   = "#{e.message}"
            status = 500
          end

          log(component.id, status, e)

          { 'body' => body, 'status' => status }
        end

        def log(id, status, e = nil)
          logger.info("Broker::Response #{id}:#{status} #{error_for(e)}")
        end

        def error_for(e)
          e.nil? ? nil : "#{e.message}\n#{e.backtrace.join('\n')}"
        end

      end
    end
  end
end

