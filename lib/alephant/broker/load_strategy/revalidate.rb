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
      class Revalidate
        include Logger

        def initialize(url_generator)
          @url_generator = url_generator
        end

        def load(component_meta)
          loaded_content = cache_object(component_meta)

          if loaded_content.expired? && !loaded_content.validating?
            Thread.new do
              logger.info "Loading new content from thread"
              loaded_content.now_validating
              cache.set(component_meta.cache_key, loaded_content)
              loaded_content.update(content(component_meta))
              cache.set(component_meta.cache_key, loaded_content)
            end
          end

          {
            :content      => loaded_content.content,
            :content_type => loaded_content.content_type
          }
        end

        private

        attr_reader :cache, :url_generator

        def cache
          @cache ||= Cache::Client.new
        end

        def cache_object(component_meta)
          cache.get(component_meta.cache_key) do
            logger.info "No cache so loading and adding cache object"
            loaded_content = content(component_meta)
            Alephant::Broker::LoadStrategy::CacheObject.new(loaded_content[:content], loaded_content[:content_type])
          end
        end

        def content(component_meta)
          resp = request component_meta

          {
            :content      => resp.body,
            :content_type => extract_content_type_from(resp.env.response_headers)
          }
        end

        def extract_content_type_from(headers)
          headers["content-type"].split(";").first
        end

        def request(component_meta)
          component_meta.cached = false
          Faraday.get(url_for(component_meta)).tap do |r|
            raise Alephant::Broker::Errors::ContentNotFound unless r.success?
          end
        end

        def url_for(component_meta)
          url_generator.generate(
            component_meta.id,
            component_meta.options
          )
        end
      end
    end
  end
end
