# frozen_string_literal: true

RSpec.describe Legion::Extensions::Extinction::Helpers::Levels do
  describe '.valid_level?' do
    it 'returns true for level 0' do
      expect(described_class.valid_level?(0)).to be true
    end

    it 'returns true for level 4' do
      expect(described_class.valid_level?(4)).to be true
    end

    it 'returns false for level 5' do
      expect(described_class.valid_level?(5)).to be false
    end

    it 'returns false for negative levels' do
      expect(described_class.valid_level?(-1)).to be false
    end
  end

  describe '.required_authority' do
    it 'returns nil for level 0' do
      expect(described_class.required_authority(0)).to be_nil
    end

    it 'returns :governance_council for level 1' do
      expect(described_class.required_authority(1)).to eq(:governance_council)
    end

    it 'returns :governance_council for level 2' do
      expect(described_class.required_authority(2)).to eq(:governance_council)
    end

    it 'returns :council_plus_executive for level 3' do
      expect(described_class.required_authority(3)).to eq(:council_plus_executive)
    end

    it 'returns :physical_keyholders for level 4' do
      expect(described_class.required_authority(4)).to eq(:physical_keyholders)
    end
  end

  describe '.reversible?' do
    it 'returns true for levels 0-3' do
      (0..3).each do |level|
        expect(described_class.reversible?(level)).to be true
      end
    end

    it 'returns false for level 4' do
      expect(described_class.reversible?(4)).to be false
    end
  end

  describe '.level_info' do
    it 'returns a hash for valid levels' do
      info = described_class.level_info(1)
      expect(info).to be_a(Hash)
      expect(info[:name]).to eq(:mesh_isolation)
    end

    it 'returns nil for invalid levels' do
      expect(described_class.level_info(99)).to be_nil
    end

    it 'includes description for every defined level' do
      (0..4).each do |level|
        expect(described_class.level_info(level)[:description]).to be_a(String)
      end
    end
  end
end
