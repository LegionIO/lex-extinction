# lex-extinction

Five-level safety containment and termination protocol for LegionIO agents. Provides escalating isolation, suspension, lockdown, and irreversible cryptographic erasure, with authority-gated transitions at each level.

## Containment Levels

| Level | Name | Authority Required | Reversible |
|-------|------|--------------------|------------|
| 0 | Normal | none | yes |
| 1 | Mesh isolation | governance council | yes |
| 2 | Capability suspension | governance council | yes |
| 3 | Memory lockdown | council + executive | yes |
| 4 | Cryptographic erasure | physical keyholders | **no** |

## Installation

```ruby
gem 'lex-extinction'
```

## Usage

```ruby
require 'legion/extensions/extinction'

client = Legion::Extensions::Extinction::Client.new

# Check current protocol state
client.extinction_status
# => { success: true, state: { current_level: 0, level_name: :normal, ... }, level_info: { ... } }

# Escalate to mesh isolation
client.escalate(level: 1, authority: :governance_council, reason: 'Anomalous behavior detected')
# => { success: true, previous_level: 0, current_level: 1 }

# De-escalate when resolved
client.deescalate(target_level: 0, authority: :governance_council, reason: 'Issue resolved')
# => { success: true, previous_level: 1, current_level: 0 }

# Full termination (governance check + archive + escalate to level 4)
client.full_termination(
  agent_id: 'agent-42',
  authority: :physical_keyholders,
  reason: 'Unrecoverable safety violation'
)
```

## Runner Methods

| Method | Key Args | Returns |
|--------|----------|---------|
| `escalate` | `level:, authority:, reason:` | `{ success:, previous_level:, current_level: }` |
| `deescalate` | `target_level:, authority:, reason:` | `{ success:, previous_level:, current_level: }` |
| `extinction_status` | — | `{ success:, state:, level_info: }` |
| `monitor_protocol` | — | `{ success:, state:, stale:, checked_at: }` |
| `archive_agent` | `agent_id:, reason:, metadata: {}` | `{ success:, archive: }` |
| `full_termination` | `agent_id:, authority:, reason:` | governance check → archive → escalate(4) |

## Configuration

```yaml
extinction:
  governance_required: true       # check lex-governance before full_termination
  archive_on_escalate: false      # auto-archive at level >= 3
  stale_threshold_hours: 24       # hours before monitor reports stale protocol state
  monitor_interval: 300           # seconds between background monitor ticks
```

## Actors

| Actor | Interval | What It Does |
|-------|----------|--------------|
| `ProtocolMonitor` | Every 300s | Checks protocol state and reports whether it is stale |

## Architecture Notes

- Level 4 (cryptographic erasure) triggers `lex-privatecore`'s `full_erasure` on all memory traces (guarded with `defined?`).
- State is persisted to `Legion::Data::Local` when available; falls back to in-memory storage.
- All escalations/de-escalations fire `Legion::Events` notifications (`extinction.escalated`, `extinction.deescalated`, `extinction.level_N`) and write to `Legion::Extensions::Audit`.
- `lex-governance` integration is guarded with `defined?()` — the gem functions without it.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
