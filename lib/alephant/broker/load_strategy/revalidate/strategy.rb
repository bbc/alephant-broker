require "alephant/broker/cache"
require "alephant/broker/errors"
require "alephant/logger"
require "faraday"

# ref: http://bit.ly/1svnJue
#
# - user makes a request for content and they're routed to the broker which will attempt to handle that request
# - the broker goes direct to S3 for the content and returns it to the user
# - this content could be stale or it could have been put there very recently
# - before giving the content back to the user, we check the TTL of the S3 object
# - if the TTL on the S3 object has expired then we send the content to the user (and kickstart the process to get the content updated)
# - if the TTL on the S3 object hasn't expired then we send the content to the user (do nothing else)
# - check dynamo to see if we're already waiting for component_foo to be re-rendered
# - if there is a record already in dynamo then do nothing more, as we're already waiting for a renderer to do a re-render
# - if there isn't a record in dynamo, then put one in to say "component_foo = true" (or just something to indicate the component needs to be re-rendered)
# - at this point we'll also put a message into SQS (which the renderer will be configured to pick up)
# - the renderer will then pick up the SQS message, see it's a request to re-render the content and it'll go ahead and do that
# - once the renderer has rendered the content, it'll overwrite the location in S3 and update the TTL on the object in S3
# - the renderer will also do some clean up to remove the record from dynamo
# - the use of redis, is simply to not exhaust the dynamodb iops threshold we set, but that can be ignored for now as we can scale up differently if need be

module Alephant
  module Broker
    module LoadStrategy
      module Revalidate
        class Strategy
          include Logger

          def load(component_meta)
            loaded_content = cached_object(component_meta)

            if loaded_content.expired?
              Thread.new do
                logger.info "Loading new content from thread"
                Refresher.new(component_meta).refresh
              end
            end

            {
              :content      => loaded_content.content,
              :content_type => loaded_content.content_type
            }
          end

          private

          attr_reader :cache

          def cache
            @cache ||= Cache::Client.new
          end

          def cached_object(component_meta)
            cache.get(component_meta.component_key) do
              logger.info "No cache so loading and adding cache object"
              Fetcher.new(component_meta).fetch
            end
          end
        end
      end
    end
  end
end
