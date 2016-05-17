require "spec_helper"

describe Alephant::Broker::ComponentMeta do
  let(:id) { "foo" }
  let(:batch_id) { "bar" }
  let(:options) do
    {
      "variant" => "K03000001"
    }
  end
  subject { described_class.new(id, batch_id, options) }

  describe '#options' do
    let(:expected) do
      {
        :variant => "K03000001"
      }
    end

    specify { expect(subject.options).to eq expected }
  end
end
