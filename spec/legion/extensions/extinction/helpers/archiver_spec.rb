# frozen_string_literal: true

RSpec.describe Legion::Extensions::Extinction::Helpers::Archiver do
  subject(:archiver) { described_class.new }

  describe '#archive' do
    it 'returns an archive record hash' do
      record = archiver.archive(agent_id: 'agent-1', reason: 'test termination')
      expect(record).to be_a(Hash)
      expect(record[:agent_id]).to eq('agent-1')
      expect(record[:reason]).to eq('test termination')
    end

    it 'includes an archived_at timestamp' do
      record = archiver.archive(agent_id: 'agent-2', reason: 'test')
      expect(record[:archived_at]).to be_a(String)
    end

    it 'stores metadata when provided' do
      record = archiver.archive(agent_id: 'agent-3', reason: 'test', metadata: { foo: :bar })
      expect(record[:metadata]).to eq({ foo: :bar })
    end

    it 'defaults metadata to empty hash' do
      record = archiver.archive(agent_id: 'agent-4', reason: 'test')
      expect(record[:metadata]).to eq({})
    end
  end

  describe '#all_archives' do
    it 'returns empty array initially' do
      expect(archiver.all_archives).to eq([])
    end

    it 'accumulates archives across calls' do
      archiver.archive(agent_id: 'a1', reason: 'r1')
      archiver.archive(agent_id: 'a2', reason: 'r2')
      expect(archiver.all_archives.size).to eq(2)
    end
  end
end
