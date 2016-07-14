$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")

require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
end

require "pry"
require "json"
require "rack/test"
require "timecop"

require "alephant/broker"

ENV["RACK_ENV"] = "test"

RSpec.configure do |config|
  config.order = "random"
end
