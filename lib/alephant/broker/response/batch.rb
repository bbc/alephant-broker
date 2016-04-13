require "alephant/logger"
require "crimp"

module Alephant
  module Broker
    module Response
      class Batch < Base
        include Logger

        attr_reader :components, :batch_id

        def initialize(components, batch_id, env)
          @components = components
          @batch_id   = batch_id

          if component_not_modified(batch_response_headers, env)
            @status = 304
          else
            @status = 200
          end

          super(@status, "application/json")

          @headers.merge!(batch_response_headers)
        end

        def setup
          @content = ::JSON.generate({
            'batch_id' => batch_id,
            'components' => json
          })
        end

        private

        def json
          logger.info "Broker: Batch load started (#{batch_id})"
          components.map do |component|
            {
              "component"    => component.id,
              "options"      => component.options,
              "status"       => component.status,
              "content_type" => component.content_type,
              "body"         => component.content
            }
          end.tap {
            logger.info "Broker: Batch load done (#{batch_id})"
            logger.metric "BrokerBatchLoadCount"
          }
        end

        def batch_response_headers
          {
            "ETag"          => batch_response_etag,
            "Last-Modified" => batch_response_last_modified
          }
        end

        def batch_response_etag
          etags = components.map do |component|
            component.headers["ETag"]
          end.compact.sort

          Crimp.signature(etags)
        end

        def batch_response_last_modified
          last_modifieds  = components.map do |component|
            component.headers["Last-Modified"]
          end.compact

          last_modifieds.max
        end
      end
    end
  end
end
