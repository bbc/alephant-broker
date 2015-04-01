require_relative "../spec_helper"
require "rspec/expectations"

RSpec::Matchers.define :include_case_sensitive do |expected|
  match do |actual|
    actual.keys.one? { |k| expected == k }
  end
end


