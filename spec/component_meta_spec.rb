require_relative 'spec_helper'

describe Alephant::Broker::ComponentMeta do
  subject { described_class.new env }
  let(:id) { "foo" }
  let(:batch_id) { "bar" }
  let(:options) do
    {
      'variant' => 'K03000001'
    }
  end

  describe '#options' do
    let(:expected) do
      {
        :variant => "K03000001"
      }
    end

    specify { expect(subject.options).to eq expected }
  end
end
