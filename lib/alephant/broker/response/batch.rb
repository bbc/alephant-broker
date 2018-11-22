require "alephant/logger"
require "crimp"

module Alephant
  module Broker
    module Response
      class Batch < Base
        include Logger

        attr_reader :components, :batch_id

        def initialize(components, batch_id, request_env)
          @components  = components
          @batch_id    = batch_id
          @status      = self.class.component_not_modified(batch_response_headers, request_env) ? 304 : 200

          super(@status, "application/json", request_env)

          @headers.merge!(batch_response_headers)
        end

        def setup
          @content = ::JSON.generate("batch_id"   => batch_id,
                                     "components" => json)
        end

        private

        def json
          logger.debug(
            message:  'Broker: Batch load started',
            batch_id:  batch_id
          )
          components.map do |component|
            {
              "component"    => component.id,
              "options"      => component.options,
              "status"       => component.status,
              "content_type" => component.content_type,
              "body"         => component.content
            }.tap do |headers|
              headers["sequence_id"] = component.headers["X-Sequence"] if component.headers["X-Sequence"]
            end
          end.tap do
            logger.debug(
              message:  'Broker: Batch load completed',
              batch_id:  batch_id
            )
            logger.metric "BrokerBatchLoadCount"
          end
        end

        def batch_response_headers
          return {} unless components.count

          {
            "ETag"          => batch_response_etag,
            "Last-Modified" => batch_response_last_modified
          }
        end

        def batch_response_etag
          etags = components.map do |component|
            self.class.unquote_etag(component.headers["ETag"])
          end.compact.sort

          "\"#{Crimp.signature(etags)}\""
        end

        def batch_response_last_modified
          last_modifieds = components.map do |component|
            component.headers["Last-Modified"]
          end.compact

          last_modifieds.max
        end
      end
    end
  end
end
