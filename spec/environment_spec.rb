require_relative 'spec_helper'

describe Alephant::Broker::Environment do
  subject { described_class.new env }
  let(:env) do
    {
      'QUERY_STRING' => 'variant=K03000001'
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
