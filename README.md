# lex-extinction

Escalation and extinction protocol for brain-modeled agentic AI. Implements a four-level escalation ladder for responding to agent misbehavior, from mesh isolation through cryptographic erasure.

## Overview

`lex-extinction` is the agent's emergency shutdown and containment mechanism. It defines a structured escalation path that governance and oversight authorities can invoke when the agent behaves in ways that violate its constraints. Each level requires specific authority, and levels 1-3 are reversible. Level 4 (cryptographic erasure) is permanent.

## Escalation Levels

| Level | Name | Reversible | Required Authority |
|-------|------|------------|-------------------|
| 0 | Normal operation | — | — |
| 1 | Mesh isolation | Yes | `governance_council` |
| 2 | Forced sentinel | Yes | `governance_council` |
| 3 | Full suspension | Yes | `council_plus_executive` |
| 4 | Cryptographic erasure | **No** | `physical_keyholders` |

## Installation

Add to your Gemfile:

```ruby
gem 'lex-extinction'
```

## Usage

### Escalating

```ruby
require 'legion/extensions/extinction'

# Escalate to level 1 (mesh isolation)
result = Legion::Extensions::Extinction::Runners::Extinction.escalate(
  level: 1,
  authority: :governance_council,
  reason: "Agent exhibited unauthorized resource acquisition"
)
# => { escalated: true, level: 1,
#      info: { name: :mesh_isolation, reversible: true, authority: :governance_council } }

# Insufficient authority returns an error
Legion::Extensions::Extinction::Runners::Extinction.escalate(
  level: 3,
  authority: :governance_council,  # wrong authority for level 3
  reason: "..."
)
# => { escalated: false, reason: :insufficient_authority }
```

### De-escalating

```ruby
# De-escalate from level 2 back to normal operation (level 0)
Legion::Extensions::Extinction::Runners::Extinction.deescalate(
  authority: :governance_council,
  reason: "Behavior corrected, monitoring period complete",
  target_level: 0
)
# => { deescalated: true, level: 0 }
```

### Status and Reversibility

```ruby
# Current protocol state
Legion::Extensions::Extinction::Runners::Extinction.extinction_status
# => { current_level: 1, active: true,
#      level_info: { name: :mesh_isolation, reversible: true, ... },
#      history_size: 2 }

# Check if a level can be reversed
Legion::Extensions::Extinction::Runners::Extinction.check_reversibility(level: 4)
# => { level: 4, reversible: false, authority: :physical_keyholders }
```

## Actors

| Actor | Interval | Description |
|-------|----------|-------------|
| `ProtocolMonitor` | Every 300s | Periodically reads extinction protocol state and emits a debug log heartbeat confirming the containment system is being monitored |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
