require "spec_helper"

RSpec.describe Alephant::Broker::LoadStrategy::Revalidate do
  subject { described_class.new(url_generator) }

  let(:url_generator) { double(:generate => "http://foo.bar") }
end
