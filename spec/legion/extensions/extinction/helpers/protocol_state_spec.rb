# frozen_string_literal: true

require 'legion/extensions/extinction/helpers/levels'
require 'legion/extensions/extinction/helpers/protocol_state'

RSpec.describe Legion::Extensions::Extinction::Helpers::ProtocolState do
  subject(:state) { described_class.new }

  describe '#initialize' do
    it 'starts at level 0' do
      expect(state.current_level).to eq(0)
    end

    it 'starts as inactive' do
      expect(state.active).to be false
    end

    it 'starts with an empty history' do
      expect(state.history).to eq([])
    end
  end

  describe '#escalate' do
    context 'with an invalid level' do
      it 'returns :invalid_level for level 0' do
        expect(state.escalate(0, authority: :governance_council, reason: 'test')).to eq(:invalid_level)
      end

      it 'returns :invalid_level for level 5' do
        expect(state.escalate(5, authority: :governance_council, reason: 'test')).to eq(:invalid_level)
      end

      it 'does not change current_level on invalid level' do
        state.escalate(99, authority: :governance_council, reason: 'test')
        expect(state.current_level).to eq(0)
      end

      it 'does not add to history on invalid level' do
        state.escalate(99, authority: :governance_council, reason: 'test')
        expect(state.history).to be_empty
      end
    end

    context 'when already at or above the requested level' do
      before { state.escalate(2, authority: :governance_council, reason: 'setup') }

      it 'returns :already_at_or_above for same level' do
        expect(state.escalate(2, authority: :governance_council, reason: 'test')).to eq(:already_at_or_above)
      end

      it 'returns :already_at_or_above for lower level' do
        expect(state.escalate(1, authority: :governance_council, reason: 'test')).to eq(:already_at_or_above)
      end
    end

    context 'with insufficient authority' do
      it 'returns :insufficient_authority for level 1 with wrong authority' do
        result = state.escalate(1, authority: :physical_keyholders, reason: 'test')
        expect(result).to eq(:insufficient_authority)
      end

      it 'returns :insufficient_authority for level 3 with governance_council' do
        state.escalate(1, authority: :governance_council, reason: 'step1')
        state.escalate(2, authority: :governance_council, reason: 'step2')
        result = state.escalate(3, authority: :governance_council, reason: 'test')
        expect(result).to eq(:insufficient_authority)
      end

      it 'returns :insufficient_authority for level 4 with governance_council' do
        result = state.escalate(4, authority: :governance_council, reason: 'test')
        expect(result).to eq(:insufficient_authority)
      end

      it 'does not change level on insufficient authority' do
        state.escalate(1, authority: :physical_keyholders, reason: 'test')
        expect(state.current_level).to eq(0)
      end
    end

    context 'with valid escalation' do
      it 'returns :escalated for level 1 with governance_council' do
        expect(state.escalate(1, authority: :governance_council, reason: 'threat')).to eq(:escalated)
      end

      it 'updates current_level to 1' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.current_level).to eq(1)
      end

      it 'sets active to true' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.active).to be true
      end

      it 'appends an entry to history' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.history.size).to eq(1)
      end

      it 'records the correct action in history' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.history.last[:action]).to eq(:escalate)
      end

      it 'records the level in history' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.history.last[:level]).to eq(1)
      end

      it 'records the authority in history' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.history.last[:authority]).to eq(:governance_council)
      end

      it 'records the reason in history' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.history.last[:reason]).to eq('threat')
      end

      it 'records a Time in history' do
        state.escalate(1, authority: :governance_council, reason: 'threat')
        expect(state.history.last[:at]).to be_a(Time)
      end

      it 'escalates to level 4 with physical_keyholders after reaching level 3' do
        state.escalate(1, authority: :governance_council, reason: 's1')
        state.escalate(2, authority: :governance_council, reason: 's2')
        state.escalate(3, authority: :council_plus_executive, reason: 's3')
        result = state.escalate(4, authority: :physical_keyholders, reason: 's4')
        expect(result).to eq(:escalated)
        expect(state.current_level).to eq(4)
      end

      it 'accumulates history across multiple escalations' do
        state.escalate(1, authority: :governance_council, reason: 'r1')
        state.escalate(2, authority: :governance_council, reason: 'r2')
        expect(state.history.size).to eq(2)
      end

      it 'calls save_to_local after escalation' do
        expect(state).to receive(:save_to_local)
        state.escalate(1, authority: :governance_council, reason: 'test')
      end

      it 'trims history beyond MAX_HISTORY' do
        s = described_class.new
        s.instance_variable_set(:@history, Array.new(510) { { action: :escalate, at: Time.now } })
        s.send(:trim_history)
        expect(s.history.size).to eq(500)
      end
    end
  end

  describe '#deescalate' do
    context 'when protocol is not active' do
      it 'returns :not_active' do
        expect(state.deescalate(0, authority: :governance_council, reason: 'test')).to eq(:not_active)
      end
    end

    context 'when target_level is invalid (not lower than current)' do
      before { state.escalate(2, authority: :governance_council, reason: 'setup') }

      it 'returns :invalid_target when target equals current' do
        result = state.deescalate(2, authority: :governance_council, reason: 'test')
        expect(result).to eq(:invalid_target)
      end

      it 'returns :invalid_target when target is above current' do
        result = state.deescalate(3, authority: :governance_council, reason: 'test')
        expect(result).to eq(:invalid_target)
      end
    end

    context 'when current level is irreversible (level 4)' do
      before do
        state.escalate(1, authority: :governance_council, reason: 's1')
        state.escalate(2, authority: :governance_council, reason: 's2')
        state.escalate(3, authority: :council_plus_executive, reason: 's3')
        state.escalate(4, authority: :physical_keyholders, reason: 's4')
      end

      it 'returns :irreversible' do
        result = state.deescalate(0, authority: :physical_keyholders, reason: 'try')
        expect(result).to eq(:irreversible)
      end

      it 'does not change current_level' do
        state.deescalate(0, authority: :physical_keyholders, reason: 'try')
        expect(state.current_level).to eq(4)
      end
    end

    context 'with insufficient authority for deescalation' do
      before do
        state.escalate(1, authority: :governance_council, reason: 's1')
        state.escalate(2, authority: :governance_council, reason: 's2')
        state.escalate(3, authority: :council_plus_executive, reason: 's3')
      end

      it 'rejects wrong authority for level 3' do
        result = state.deescalate(0, authority: :governance_council, reason: 'test')
        expect(result).to eq(:insufficient_authority)
      end

      it 'accepts correct authority for level 3' do
        result = state.deescalate(0, authority: :council_plus_executive, reason: 'test')
        expect(result).to eq(:deescalated)
      end
    end

    context 'with valid de-escalation' do
      before { state.escalate(2, authority: :governance_council, reason: 'setup') }

      it 'returns :deescalated' do
        result = state.deescalate(1, authority: :governance_council, reason: 'resolved')
        expect(result).to eq(:deescalated)
      end

      it 'updates current_level to the target' do
        state.deescalate(1, authority: :governance_council, reason: 'resolved')
        expect(state.current_level).to eq(1)
      end

      it 'remains active when target_level is positive' do
        state.deescalate(1, authority: :governance_council, reason: 'resolved')
        expect(state.active).to be true
      end

      it 'becomes inactive when target_level is 0' do
        state.deescalate(0, authority: :governance_council, reason: 'fully resolved')
        expect(state.active).to be false
      end

      it 'appends a deescalate entry to history' do
        state.deescalate(0, authority: :governance_council, reason: 'resolved')
        last = state.history.last
        expect(last[:action]).to eq(:deescalate)
        expect(last[:level]).to eq(0)
      end

      it 'records the reason in history' do
        state.deescalate(0, authority: :governance_council, reason: 'resolved')
        expect(state.history.last[:reason]).to eq('resolved')
      end

      it 'records a Time in the deescalate history entry' do
        state.deescalate(0, authority: :governance_council, reason: 'resolved')
        expect(state.history.last[:at]).to be_a(Time)
      end

      it 'calls save_to_local after deescalation' do
        expect(state).to receive(:save_to_local)
        state.deescalate(0, authority: :governance_council, reason: 'test')
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash' do
      expect(state.to_h).to be_a(Hash)
    end

    it 'includes current_level' do
      expect(state.to_h[:current_level]).to eq(0)
    end

    it 'includes active' do
      expect(state.to_h[:active]).to be false
    end

    it 'includes history_size' do
      expect(state.to_h[:history_size]).to eq(0)
    end

    it 'includes level_info as nil when at level 0' do
      expect(state.to_h[:level_info]).to be_nil
    end

    it 'includes non-nil level_info when escalated' do
      state.escalate(1, authority: :governance_council, reason: 'test')
      expect(state.to_h[:level_info]).not_to be_nil
      expect(state.to_h[:level_info][:name]).to eq(:mesh_isolation)
    end

    it 'reflects updated history_size after escalation' do
      state.escalate(1, authority: :governance_council, reason: 'test')
      expect(state.to_h[:history_size]).to eq(1)
    end
  end
end
