# frozen_string_literal: true

require 'sequel'
require 'sequel/extensions/migration'

require 'legion/extensions/extinction/helpers/levels'
require 'legion/extensions/extinction/helpers/protocol_state'

MIGRATIONS_PATH = File.expand_path(
  '../lib/legion/extensions/extinction/local_migrations',
  __dir__
).freeze

# Minimal stub for Legion::Data::Local used only within this spec file.
module Legion
  module Data
    module Local
      class << self
        attr_accessor :_connection, :_connected

        def connection
          _connection
        end

        def connected?
          _connected == true
        end

        def reset_test!
          self._connection = nil
          self._connected = false
        end
      end
    end
  end
end

RSpec.describe Legion::Extensions::Extinction::Helpers::ProtocolState do
  let(:db) do
    conn = Sequel.sqlite
    Sequel::TimestampMigrator.new(conn, MIGRATIONS_PATH).run
    conn
  end

  before do
    Legion::Data::Local._connection = db
    Legion::Data::Local._connected = true
  end

  after do
    Legion::Data::Local.reset_test!
  end

  describe 'save and load round-trip' do
    it 'persists current_level via save_to_local and restores it on a new instance' do
      state = described_class.new
      state.escalate(1, authority: :governance_council, reason: 'test threat')
      state.save_to_local

      restored = described_class.new
      expect(restored.current_level).to eq(1)
    end

    it 'persists active flag' do
      state = described_class.new
      state.escalate(1, authority: :governance_council, reason: 'threat')
      state.save_to_local

      restored = described_class.new
      expect(restored.active).to be true
    end

    it 'persists history entries' do
      state = described_class.new
      state.escalate(1, authority: :governance_council, reason: 'threat')
      state.save_to_local

      restored = described_class.new
      expect(restored.history.size).to eq(1)
      expect(restored.history.first[:action]).to eq(:escalate)
      expect(restored.history.first[:level]).to eq(1)
      expect(restored.history.first[:reason]).to eq('threat')
    end

    it 'restores history :at as a Time object' do
      state = described_class.new
      state.escalate(1, authority: :governance_council, reason: 'threat')
      state.save_to_local

      restored = described_class.new
      expect(restored.history.first[:at]).to be_a(Time)
    end

    it 'saves and loads an inactive protocol at level 0' do
      state = described_class.new
      # state is at level 0, no escalation
      state.save_to_local

      restored = described_class.new
      expect(restored.current_level).to eq(0)
      expect(restored.active).to be false
    end

    it 'updates the existing row on a second save rather than inserting a duplicate' do
      state = described_class.new
      state.escalate(1, authority: :governance_council, reason: 'first')
      state.save_to_local

      state.escalate(2, authority: :governance_council, reason: 'second')
      state.save_to_local

      expect(db[:extinction_state].count).to eq(1)

      restored = described_class.new
      expect(restored.current_level).to eq(2)
    end
  end

  describe 'level-4 irreversibility across restarts' do
    it 'starts at level 4 when DB contains level 4' do
      # Directly insert a level-4 row to simulate a previous escalation
      db[:extinction_state].insert(
        id:            1,
        current_level: 4,
        active:        true,
        history:       '[]',
        updated_at:    Time.now.utc
      )

      state = described_class.new
      expect(state.current_level).to eq(4)
    end

    it 'cannot be de-escalated after reloading level 4 from DB' do
      db[:extinction_state].insert(
        id:            1,
        current_level: 4,
        active:        true,
        history:       '[]',
        updated_at:    Time.now.utc
      )

      state = described_class.new
      result = state.deescalate(0, authority: :physical_keyholders, reason: 'trying to escape')
      expect(result).to eq(:irreversible)
    end

    it 'uses max(db_level, in-memory level) so a fresh instance never drops below DB level' do
      db[:extinction_state].insert(
        id:            1,
        current_level: 3,
        active:        true,
        history:       '[]',
        updated_at:    Time.now.utc
      )

      state = described_class.new
      # In-memory starts at 0, DB has 3, so max(3, 0) = 3
      expect(state.current_level).to eq(3)
    end
  end

  describe 'graceful no-op when Local is not connected' do
    before do
      Legion::Data::Local._connected = false
      Legion::Data::Local._connection = nil
    end

    it 'initializes normally when Local is disconnected' do
      state = described_class.new
      expect(state.current_level).to eq(0)
      expect(state.active).to be false
      expect(state.history).to eq([])
    end

    it 'save_to_local returns nil without raising when disconnected' do
      state = described_class.new
      expect { state.save_to_local }.not_to raise_error
    end

    it 'does not mutate state during save_to_local when disconnected' do
      state = described_class.new
      state.escalate(1, authority: :governance_council, reason: 'test')
      state.save_to_local
      expect(state.current_level).to eq(1)
    end
  end
end
