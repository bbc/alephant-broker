module Alephant
  module Broker
    module LoadStrategy
      module Revalidate
        class Refresher
          include Logger

          INFLIGHT_CACHE_TTL = 120 # expire the inflight key after 2 minutes

          attr_reader :component_meta

          def initialize(component_meta)
            @component_meta = component_meta
          end

          def refresh
            inflight = cache.get(inflight_cache_key)

            logger.info(event: 'Inflight?', cache_val: inflight, method: "#{self.class}#refresh")

            return if inflight

            logger.info(event: 'QueueMessage', message: message, method: "#{self.class}#refresh")

            client.send_message(
              queue_url: queue_url,
              message_body: message
              )

            cache.set(inflight_cache_key, true, INFLIGHT_CACHE_TTL)
          end

          private

          def client
            options = {}
            options[:endpoint] = ENV['AWS_SQS_ENDPOINT'] if ENV['AWS_SQS_ENDPOINT']
            options[:queue_owner_aws_account_id] = aws_acc_id if aws_acc_id

            @client ||= Aws::SQS::Client.new(options)
          end

          def queue_url
            options = {
              queue_name: Broker.config[:sqs_queue_name]
            }

            client.get_queue_url(options).queue_url
          end

          def message
            ::JSON.generate(id:        component_meta.id,
                            batch_id:  component_meta.batch_id,
                            options:   component_meta.options,
                            timestamp: Time.now.to_s)
          end

          def aws_acc_id
            Broker.config[:aws_account_id]
          end

          def cache
            @cache ||= Cache::Client.new
          end

          def cache_key
            component_meta.component_key
          end

          def inflight_cache_key
            "inflight-#{cache_key}"
          end
        end
      end
    end
  end
end
