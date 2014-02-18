require 'spec_helper'

describe ComponentCache::Application do
  subject { ComponentCache::Application.new }
  it { should respond_to(:call).with(1).argument }
end
