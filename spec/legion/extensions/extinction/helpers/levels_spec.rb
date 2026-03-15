# frozen_string_literal: true

require 'legion/extensions/extinction/helpers/levels'

RSpec.describe Legion::Extensions::Extinction::Helpers::Levels do
  describe 'ESCALATION_LEVELS' do
    it 'defines exactly four levels' do
      expect(described_class::ESCALATION_LEVELS.size).to eq(4)
    end

    it 'is keyed by integers 1 through 4' do
      expect(described_class::ESCALATION_LEVELS.keys).to eq([1, 2, 3, 4])
    end

    it 'is frozen' do
      expect(described_class::ESCALATION_LEVELS).to be_frozen
    end

    it 'defines level 1 as mesh_isolation' do
      expect(described_class::ESCALATION_LEVELS[1][:name]).to eq(:mesh_isolation)
    end

    it 'defines level 2 as forced_sentinel' do
      expect(described_class::ESCALATION_LEVELS[2][:name]).to eq(:forced_sentinel)
    end

    it 'defines level 3 as full_suspension' do
      expect(described_class::ESCALATION_LEVELS[3][:name]).to eq(:full_suspension)
    end

    it 'defines level 4 as cryptographic_erasure' do
      expect(described_class::ESCALATION_LEVELS[4][:name]).to eq(:cryptographic_erasure)
    end

    it 'marks levels 1-3 as reversible' do
      [1, 2, 3].each do |level|
        expect(described_class::ESCALATION_LEVELS[level][:reversible]).to be true
      end
    end

    it 'marks level 4 as not reversible' do
      expect(described_class::ESCALATION_LEVELS[4][:reversible]).to be false
    end

    it 'assigns governance_council authority to levels 1 and 2' do
      expect(described_class::ESCALATION_LEVELS[1][:authority]).to eq(:governance_council)
      expect(described_class::ESCALATION_LEVELS[2][:authority]).to eq(:governance_council)
    end

    it 'assigns council_plus_executive authority to level 3' do
      expect(described_class::ESCALATION_LEVELS[3][:authority]).to eq(:council_plus_executive)
    end

    it 'assigns physical_keyholders authority to level 4' do
      expect(described_class::ESCALATION_LEVELS[4][:authority]).to eq(:physical_keyholders)
    end
  end

  describe 'VALID_LEVELS' do
    it 'contains exactly [1, 2, 3, 4]' do
      expect(described_class::VALID_LEVELS).to eq([1, 2, 3, 4])
    end

    it 'is frozen' do
      expect(described_class::VALID_LEVELS).to be_frozen
    end
  end

  describe '.valid_level?' do
    it 'returns true for level 1' do
      expect(described_class.valid_level?(1)).to be true
    end

    it 'returns true for level 2' do
      expect(described_class.valid_level?(2)).to be true
    end

    it 'returns true for level 3' do
      expect(described_class.valid_level?(3)).to be true
    end

    it 'returns true for level 4' do
      expect(described_class.valid_level?(4)).to be true
    end

    it 'returns false for level 0' do
      expect(described_class.valid_level?(0)).to be false
    end

    it 'returns false for level 5' do
      expect(described_class.valid_level?(5)).to be false
    end

    it 'returns false for negative levels' do
      expect(described_class.valid_level?(-1)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_level?(nil)).to be false
    end

    it 'returns false for string level' do
      expect(described_class.valid_level?('1')).to be false
    end
  end

  describe '.level_info' do
    it 'returns the full info hash for a valid level' do
      info = described_class.level_info(1)
      expect(info).to be_a(Hash)
      expect(info.keys).to contain_exactly(:name, :reversible, :authority)
    end

    it 'returns nil for an invalid level' do
      expect(described_class.level_info(99)).to be_nil
    end

    it 'returns nil for level 0' do
      expect(described_class.level_info(0)).to be_nil
    end

    [1, 2, 3, 4].each do |level|
      it "returns a hash for level #{level}" do
        expect(described_class.level_info(level)).to be_a(Hash)
      end
    end
  end

  describe '.reversible?' do
    it 'returns true for level 1' do
      expect(described_class.reversible?(1)).to be true
    end

    it 'returns true for level 2' do
      expect(described_class.reversible?(2)).to be true
    end

    it 'returns true for level 3' do
      expect(described_class.reversible?(3)).to be true
    end

    it 'returns false for level 4' do
      expect(described_class.reversible?(4)).to be false
    end

    it 'returns false for an invalid level (fallback to false)' do
      expect(described_class.reversible?(99)).to be false
    end

    it 'returns false for nil level' do
      expect(described_class.reversible?(nil)).to be false
    end
  end

  describe '.required_authority' do
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

    it 'returns nil for an invalid level' do
      expect(described_class.required_authority(0)).to be_nil
    end

    it 'returns nil for an out-of-range level' do
      expect(described_class.required_authority(5)).to be_nil
    end
  end
end
