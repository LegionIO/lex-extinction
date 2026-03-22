# frozen_string_literal: true

require 'legion/extensions/extinction/client'

RSpec.describe Legion::Extensions::Extinction::Runners::Extinction do
  subject(:client) { Legion::Extensions::Extinction::Client.new }

  describe '#extinction_status' do
    it 'returns success: true' do
      result = client.extinction_status
      expect(result[:success]).to be true
    end

    it 'includes state hash' do
      result = client.extinction_status
      expect(result[:state]).to be_a(Hash)
    end

    it 'starts at level 0' do
      result = client.extinction_status
      expect(result[:state][:current_level]).to eq(0)
    end
  end

  describe '#escalate' do
    it 'escalates to level 1 with proper authority' do
      result = client.escalate(level: 1, authority: :governance_council, reason: 'test')
      expect(result[:success]).to be true
      expect(result[:current_level]).to eq(1)
    end

    it 'fails with invalid level' do
      result = client.escalate(level: 99, authority: :governance_council, reason: 'test')
      expect(result[:success]).to be false
    end

    it 'fails with wrong authority' do
      result = client.escalate(level: 4, authority: :governance_council, reason: 'wrong')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:insufficient_authority)
    end
  end

  describe '#deescalate' do
    before { client.escalate(level: 2, authority: :governance_council, reason: 'setup') }

    it 'deescalates to a lower level' do
      result = client.deescalate(target_level: 1, authority: :governance_council, reason: 'cooling down')
      expect(result[:success]).to be true
    end

    it 'fails when deescalating to equal or higher level' do
      result = client.deescalate(target_level: 3, authority: :governance_council, reason: 'bad')
      expect(result[:success]).to be false
    end
  end

  describe '#monitor_protocol' do
    it 'returns success: true' do
      result = client.monitor_protocol
      expect(result[:success]).to be true
    end

    it 'includes checked_at timestamp' do
      result = client.monitor_protocol
      expect(result[:checked_at]).to be_a(String)
    end

    it 'reports not stale when no history' do
      result = client.monitor_protocol
      expect(result[:stale]).to be false
    end
  end

  describe '#archive_agent' do
    it 'returns success: true' do
      result = client.archive_agent(agent_id: 'agent-x', reason: 'test')
      expect(result[:success]).to be true
    end

    it 'includes archive record' do
      result = client.archive_agent(agent_id: 'agent-x', reason: 'test')
      expect(result[:archive]).to be_a(Hash)
      expect(result[:archive][:agent_id]).to eq('agent-x')
    end
  end

  describe '#full_termination' do
    it 'returns success: true with correct authority when governance is not loaded' do
      result = client.full_termination(agent_id: 'agent-y', authority: :physical_keyholders,
                                       reason: 'end of life')
      expect(result[:success]).to be true
    end

    it 'includes terminated_at timestamp' do
      result = client.full_termination(agent_id: 'agent-z', authority: :physical_keyholders,
                                       reason: 'test')
      expect(result[:terminated_at]).to be_a(String)
    end
  end
end
