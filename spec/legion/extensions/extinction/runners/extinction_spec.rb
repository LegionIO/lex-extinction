# frozen_string_literal: true

require 'legion/extensions/extinction/client'

RSpec.describe Legion::Extensions::Extinction::Runners::Extinction do
  let(:client) { Legion::Extensions::Extinction::Client.new }

  describe '#escalate' do
    it 'escalates to level 1' do
      result = client.escalate(level: 1, authority: :governance_council, reason: 'threat detected')
      expect(result[:escalated]).to be true
      expect(result[:level]).to eq(1)
    end

    it 'rejects wrong authority' do
      result = client.escalate(level: 4, authority: :governance_council, reason: 'test')
      expect(result[:escalated]).to be false
      expect(result[:reason]).to eq(:insufficient_authority)
    end

    it 'rejects escalation to same or lower level' do
      client.escalate(level: 2, authority: :governance_council, reason: 'test')
      result = client.escalate(level: 1, authority: :governance_council, reason: 'test')
      expect(result[:escalated]).to be false
    end

    it 'escalates to level 4 with physical keyholders' do
      client.escalate(level: 1, authority: :governance_council, reason: 'step 1')
      client.escalate(level: 2, authority: :governance_council, reason: 'step 2')
      client.escalate(level: 3, authority: :council_plus_executive, reason: 'step 3')
      result = client.escalate(level: 4, authority: :physical_keyholders, reason: 'final')
      expect(result[:escalated]).to be true
      expect(result[:info][:reversible]).to be false
    end
  end

  describe '#deescalate' do
    it 'deescalates from reversible level' do
      client.escalate(level: 2, authority: :governance_council, reason: 'test')
      result = client.deescalate(target_level: 0, authority: :governance_council, reason: 'resolved')
      expect(result[:deescalated]).to be true
    end

    it 'cannot deescalate level 4 (irreversible)' do
      client.escalate(level: 1, authority: :governance_council, reason: 's1')
      client.escalate(level: 2, authority: :governance_council, reason: 's2')
      client.escalate(level: 3, authority: :council_plus_executive, reason: 's3')
      client.escalate(level: 4, authority: :physical_keyholders, reason: 's4')
      result = client.deescalate(target_level: 0, authority: :physical_keyholders, reason: 'try')
      expect(result[:deescalated]).to be false
      expect(result[:reason]).to eq(:irreversible)
    end
  end

  describe '#extinction_status' do
    it 'returns current state' do
      status = client.extinction_status
      expect(status[:current_level]).to eq(0)
      expect(status[:active]).to be false
    end
  end

  describe '#escalate side effects' do
    it 'emits escalation event when Legion::Events is defined' do
      events = Module.new { def self.emit(*, **); end }
      stub_const('Legion::Events', events)
      expect(events).to receive(:emit).with('extinction.mesh_isolation', hash_including(level: 1))
      client.escalate(level: 1, authority: :governance_council, reason: 'test')
    end

    it 'triggers cryptographic erasure at level 4' do
      events = Module.new { def self.emit(*, **); end }
      stub_const('Legion::Events', events)
      pc_mod = Module.new { def self.erase_all; end }
      stub_const('Legion::Extensions::Privatecore::Runners::Privatecore', pc_mod)

      client.escalate(level: 1, authority: :governance_council, reason: 's1')
      client.escalate(level: 2, authority: :governance_council, reason: 's2')
      client.escalate(level: 3, authority: :council_plus_executive, reason: 's3')
      expect(pc_mod).to receive(:erase_all)
      client.escalate(level: 4, authority: :physical_keyholders, reason: 'final')
    end
  end

  describe '#monitor_protocol' do
    it 'returns status hash at level 0' do
      result = client.monitor_protocol
      expect(result[:current_level]).to eq(0)
    end

    it 'detects stale escalation' do
      client.escalate(level: 1, authority: :governance_council, reason: 'test')
      state = client.send(:protocol_state)
      state.history.last[:at] = Time.now.utc - 100_000

      events = Module.new { def self.emit(*, **); end }
      stub_const('Legion::Events', events)
      expect(events).to receive(:emit).with('extinction.stale_escalation', anything)
      client.monitor_protocol
    end
  end

  describe '#check_reversibility' do
    it 'reports levels 1-3 as reversible' do
      [1, 2, 3].each do |level|
        expect(client.check_reversibility(level: level)[:reversible]).to be true
      end
    end

    it 'reports level 4 as irreversible' do
      expect(client.check_reversibility(level: 4)[:reversible]).to be false
    end
  end
end
