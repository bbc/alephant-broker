module Alephant
  module Broker
    module LoadStrategy
      module Revalidate
        class Refresher
          include Logger

          attr_reader :component_meta

          def initialize(component_meta)
            @component_meta = component_meta
          end

          def refresh
            return if cache.get(inflight_cache_key)

            logger.info(event: 'QueueMessage', message: message, method: "#{self.class}#refresh")

            queue.send_message(message)
            cache.set(inflight_cache_key, true)
          end

          private

          def message
            JSON.generate(id:        component_meta.id,
                          batch_id:  component_meta.batch_id,
                          options:   component_meta.options,
                          timestamp: Time.now.to_s)
          end

          def queue
            @queue ||= proc do
              client = AWS::SQS.new
              url    = client.queues.url_for(Broker.config[:sqs_queue_name], queue_options)

              client.queues[url]
            end.call
          end

          def queue_options
            opts = {}
            opts[:queue_owner_aws_account_id] = aws_acc_id if aws_acc_id

            logger.info(event: 'SQSQueueOptionsConfigured', options: opts, method: "#{self.class}#queue_options")

            opts
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
