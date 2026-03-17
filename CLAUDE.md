# lex-extinction

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Escalation and extinction protocol for the LegionIO cognitive architecture. Implements a four-level containment ladder with authority-gated escalation and de-escalation. Level 4 (cryptographic erasure) is irreversible. Protocol state is tracked with a capped history log and persisted to local storage.

## Gem Info

- **Gem name**: `lex-extinction`
- **Version**: `0.2.0`
- **Module**: `Legion::Extensions::Extinction`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/extinction/
  version.rb
  helpers/
    levels.rb          # ESCALATION_LEVELS hash, VALID_LEVELS, valid_level?, level_info, reversible?, required_authority
    protocol_state.rb  # ProtocolState class - current_level, active, history, MAX_HISTORY, trim_history
  runners/
    extinction.rb      # escalate, deescalate, extinction_status, monitor_protocol, check_reversibility
  actors/
    protocol_monitor.rb  # ProtocolMonitor - Every 300s, calls monitor_protocol for periodic observability
spec/
  legion/extensions/extinction/
    helpers/
      levels_spec.rb
      protocol_state_spec.rb
    runners/
      extinction_spec.rb
    actors/
      protocol_monitor_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Levels)

```ruby
ESCALATION_LEVELS = {
  1 => { name: :mesh_isolation,       reversible: true,  authority: :governance_council },
  2 => { name: :forced_sentinel,      reversible: true,  authority: :governance_council },
  3 => { name: :full_suspension,       reversible: true,  authority: :council_plus_executive },
  4 => { name: :cryptographic_erasure, reversible: false, authority: :physical_keyholders }
}
VALID_LEVELS = [1, 2, 3, 4]
```

## ProtocolState Class

State is initialized at level 0 (`:active = false`). `MAX_HISTORY = 500` caps history array.

`escalate(level, authority:, reason:)` returns a symbol, not a hash:
- `:invalid_level` - not in VALID_LEVELS
- `:already_at_or_above` - requested level <= current level
- `:insufficient_authority` - authority doesn't match required for that level
- `:escalated` - success; persists state and trims history

`deescalate(target_level, authority:, reason:)`:
- `:not_active` - protocol not active
- `:invalid_target` - target >= current (must be lower)
- `:irreversible` - current level is not reversible (level 4)
- `:insufficient_authority` - authority doesn't match required for current level
- `:deescalated` - success; persists state and trims history

`@active` is set to `false` when `target_level == 0`, true otherwise.

## Runner Methods

- `escalate` - escalates protocol level, enforces side effects (mesh isolation at L1+, cryptographic erasure at L4), emits events
- `deescalate` - de-escalates protocol level with authority validation
- `extinction_status` - reads current protocol state (legacy)
- `monitor_protocol` - enhanced monitoring: logs active state, detects stale escalations (>24hr), emits `extinction.stale_escalation` event
- `check_reversibility` - checks if a level can be de-escalated

## Side-Effect Enforcement

- **Level 1+**: Mesh isolation via `Legion::Extensions::Mesh::Runners::Mesh.disconnect` (guarded with `defined?` check)
- **Level 4**: Cryptographic erasure via `Legion::Extensions::Privatecore::Runners::Privatecore.erase_all` (guarded)
- **Level 4**: Worker termination via `Legion::Data::Model::DigitalWorker` lifecycle_state update (guarded)
- **Events**: `extinction.<level_name>` emitted on every escalation; `extinction.stale_escalation` on 24hr+ active protocols

## Actors

| Actor | Interval | Runner | Method | Purpose |
|---|---|---|---|---|
| `ProtocolMonitor` | Every 300s | `Runners::Extinction` | `monitor_protocol` | Periodic monitoring with stale escalation detection |

## Integration Points

- **lex-governance**: governance votes can trigger escalation at any level
- **lex-privatecore**: level 4 escalation triggers cryptographic erasure of memory traces
- **lex-mesh**: level 1+ escalation disconnects the agent from the mesh network
- **lex-tick**: emergency trigger `:extinction_protocol` in tick causes immediate `full_active` mode
- **legion-data**: worker termination at level 4 sets lifecycle_state to 'terminated'

## Development Notes

- Authority validation is exact symbol match — no inheritance or permission hierarchies
- De-escalation requires authority matching the required authority for the **current** level
- Level 4 cannot be reversed via `deescalate` due to the `:irreversible` check
- History is capped at 500 entries via `trim_history` after every escalate/deescalate
- State is persisted to local SQLite after every escalate/deescalate call
- `ProtocolMonitor` runs even when the protocol is inactive (level 0), providing a steady heartbeat
