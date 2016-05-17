$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")

require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
end

require "pry"
require "json"
require "rack/test"

require "alephant/broker"
require "alephant/broker/load_strategy/s3/sequenced"
require "alephant/broker/load_strategy/s3/archived"
require "alephant/broker/load_strategy/http"
require "alephant/broker/cache"
require "alephant/broker/errors/content_not_found"


ENV["RACK_ENV"] = "test"

RSpec.configure do |config|
  config.order = "random"
end
