$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'pry'
require 'json'
require 'alephant/broker'
require 'alephant/broker/load_strategy/s3/sequenced'
require 'alephant/broker/load_strategy/s3/archived'
require "alephant/broker/load_strategy/http"
require "alephant/broker/cache/client"
require "alephant/broker/cache/factory"
require "alephant/broker/errors/content_not_found"

require 'rack/test'

ENV['RACK_ENV'] = 'test'
