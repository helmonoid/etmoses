require 'rails_helper'

RSpec.describe Network::Curve do
  describe '.from' do
    context 'with an array' do
      let(:enum)  { [1, 2, 3, 4, 5] }
      let(:curve) { Network::Curve.from(enum) }

      it 'returns a Network::Curve' do
        expect(curve).to be_a(Network::Curve)
      end

      it 'contains the original values' do
        expect(curve.to_a).to eq(enum)
      end
    end

    context 'with a Network::Curve' do
      let(:enum)  { Network::Curve.new([1, 2, 3, 4, 5]) }
      let(:curve) { Network::Curve.from(enum) }

      it 'returns a Network::Curve' do
        expect(curve).to be_a(Network::Curve)
      end

      it 'returns the original object' do
        expect(curve.object_id).to eq(enum.object_id)
      end

      it 'contains the original values' do
        expect(curve.to_a).to eq([1, 2, 3, 4, 5])
      end
    end
  end

  context 'with an array of 8,760 values' do
    let(:curve) { Network::Curve.new([1] * 8760) }

    it 'has a resolution of 1' do
      expect(curve.resolution).to eq(1)
    end
  end

  context 'with an array of 35,040 values' do
    let(:curve) { Network::Curve.new([1] * 35040) }

    it 'has a resolution of 0.25' do
      expect(curve.resolution).to eq(0.25)
    end

    it 'has 4 frames per hour' do
      expect(curve.frames_per_hour).to eq(4)
    end
  end

  context 'with an array of 1,095 values' do
    let(:curve) { Network::Curve.new([1] * 1095) }

    it 'has a resolution of 8' do
      expect(curve.resolution).to eq(8)
    end

    it 'has 0.125 frames per hour' do
      expect(curve.frames_per_hour).to eq(0.125)
    end
  end

  context 'with an array of 1,460 values' do
    let(:curve) { Network::Curve.new([1] * 1460) }

    it 'has a resolution of 6' do
      expect(curve.resolution).to eq(6)
    end
  end

  context 'with an empty array and no custom length' do
    let(:curve) { Network::Curve.new([]) }

    it 'raises an error' do
      expect { curve }.to raise_error(/must not be empty/)
    end
  end

  context 'with an empty array and a custom length of 4,380' do
    let(:curve) { Network::Curve.new([], 4380) }

    it 'has a resolution of 2' do
      expect(curve.resolution).to eq(2)
    end

    it 'has 0.5 frames per hour' do
      expect(curve.frames_per_hour).to eq(0.5)
    end
  end
end
