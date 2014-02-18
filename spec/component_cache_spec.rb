require 'spec_helper'

describe Alephant::Broker do
  subject { Alephant::Broker }
  it { should respond_to(:handle).with(2).argument }
end
