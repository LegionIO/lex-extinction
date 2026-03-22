# frozen_string_literal: true

RSpec.describe Legion::Extensions::Extinction::Helpers::ProtocolState do
  subject(:state) { described_class.new }

  describe '#to_h' do
    it 'starts at level 0' do
      expect(state.to_h[:current_level]).to eq(0)
    end

    it 'reports level name as :normal at start' do
      expect(state.to_h[:level_name]).to eq(:normal)
    end

    it 'has empty history initially' do
      expect(state.to_h[:history_count]).to eq(0)
    end
  end

  describe '#escalate' do
    it 'successfully escalates to level 1 with correct authority' do
      result = state.escalate(level: 1, authority: :governance_council, reason: 'test')
      expect(result[:success]).to be true
      expect(result[:current_level]).to eq(1)
    end

    it 'fails with invalid level' do
      result = state.escalate(level: 99, authority: :governance_council, reason: 'test')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_level)
    end

    it 'fails when escalating to same or lower level' do
      state.escalate(level: 2, authority: :governance_council, reason: 'initial')
      result = state.escalate(level: 1, authority: :governance_council, reason: 'back')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_escalation)
    end

    it 'fails with insufficient authority' do
      result = state.escalate(level: 4, authority: :governance_council, reason: 'wrong auth')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:insufficient_authority)
    end

    it 'records history on successful escalation' do
      state.escalate(level: 1, authority: :governance_council, reason: 'test')
      expect(state.history.size).to eq(1)
      expect(state.history.last[:action]).to eq(:escalate)
    end
  end

  describe '#deescalate' do
    before { state.escalate(level: 2, authority: :governance_council, reason: 'setup') }

    it 'successfully deescalates to lower level' do
      result = state.deescalate(target_level: 1, authority: :governance_council, reason: 'cooling down')
      expect(result[:success]).to be true
      expect(result[:current_level]).to eq(1)
    end

    it 'fails when targeting same or higher level' do
      result = state.deescalate(target_level: 3, authority: :governance_council, reason: 'test')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_deescalation)
    end

    it 'fails when current level is not reversible' do
      state.escalate(level: 4, authority: :physical_keyholders, reason: 'terminal')
      result = state.deescalate(target_level: 3, authority: :physical_keyholders, reason: 'undo')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_reversible)
    end

    it 'fails with insufficient authority' do
      result = state.deescalate(target_level: 1, authority: :wrong_authority, reason: 'test')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:insufficient_authority)
    end

    it 'records history on successful deescalation' do
      state.deescalate(target_level: 1, authority: :governance_council, reason: 'test')
      last = state.history.last
      expect(last[:action]).to eq(:deescalate)
    end
  end

  describe 'MAX_HISTORY' do
    it 'is 500' do
      expect(described_class::MAX_HISTORY).to eq(500)
    end
  end
end
