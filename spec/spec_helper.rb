$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'pry'
require 'json'
require 'alephant/broker'
require 'alephant/broker/load_strategy/s3'
require 'rack/test'

ENV['RACK_ENV'] = 'test'
