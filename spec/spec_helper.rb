$: << File.join(File.dirname(__FILE__),"..", "app")

ENV['RACK_ENV'] = 'test'

require 'app'
require 'pry'
require 'rack/test'


