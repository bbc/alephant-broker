# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alephant/broker/version'

Gem::Specification.new do |spec|
  spec.name          = "alephant-broker"
  spec.version       = Alephant::Broker::VERSION
  spec.authors       = ["BBC News"]
  spec.email         = ["FutureMediaNewsRubyGems@bbc.co.uk"]
  spec.summary       = "Brokers requests for alephant components"
  spec.description   = "Brokers requests for alephant components"
  spec.homepage      = "https://github.com/BBC-News/alephant-broker"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-nc"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-remote"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rake-rspec", ">= 0.0.2"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"

  spec.add_runtime_dependency "alephant-lookup"
  spec.add_runtime_dependency "alephant-storage", ">= 1.1.0"
  spec.add_runtime_dependency "alephant-logger", "1.2.0"
  spec.add_runtime_dependency 'alephant-sequencer'
  spec.add_runtime_dependency "dalli-elasticache"
  spec.add_runtime_dependency "pmap"
  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "crimp"
end
