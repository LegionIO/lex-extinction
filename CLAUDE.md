# lex-extinction

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Escalation and extinction protocol for the LegionIO cognitive architecture. Implements a four-level containment ladder with authority-gated escalation and de-escalation. Level 4 (cryptographic erasure) is irreversible. Protocol state is tracked with a full history log.

## Gem Info

- **Gem name**: `lex-extinction`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Extinction`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/extinction/
  version.rb
  helpers/
    levels.rb          # ESCALATION_LEVELS hash, VALID_LEVELS, valid_level?, level_info, reversible?, required_authority
    protocol_state.rb  # ProtocolState class - current_level, active, history
  runners/
    extinction.rb      # escalate, deescalate, extinction_status, check_reversibility
  actors/
    protocol_monitor.rb  # ProtocolMonitor - Every 300s, calls extinction_status for periodic observability
spec/
  legion/extensions/extinction/
    runners/
      extinction_spec.rb
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

State is initialized at level 0 (`:active = false`).

`escalate(level, authority:, reason:)` returns a symbol, not a hash:
- `:invalid_level` - not in VALID_LEVELS
- `:already_at_or_above` - requested level <= current level
- `:insufficient_authority` - authority doesn't match required for that level
- `:escalated` - success

`deescalate(target_level, authority:, reason:)`:
- `:not_active` - protocol not active
- `:invalid_target` - target >= current (must be lower)
- `:irreversible` - current level is not reversible (level 4)
- `:deescalated` - success

`@active` is set to `false` when `target_level == 0`, true otherwise.

History is an unbounded Array appended on every escalate/deescalate call.

## Runner Mapping

The runner translates the symbol results from ProtocolState into response hashes:
- `:escalated` -> `{ escalated: true, level: level, info: level_info }`
- anything else -> `{ escalated: false, reason: result }`

## Actors

| Actor | Interval | Runner | Method | Purpose |
|---|---|---|---|---|
| `ProtocolMonitor` | Every 300s | `Runners::Extinction` | `extinction_status` | Periodic observability — logs current protocol level and active flag |

### ProtocolMonitor

Every 5 minutes calls `extinction_status`, which reads `protocol_state.to_h` and emits a debug log line with `level` and `active`. No state mutations — purely for observability. Produces a heartbeat in logs that confirms the extinction protocol is being monitored even when inactive. Uses the existing `extinction_status` runner method; no new runner code was added.

## Integration Points

- **lex-governance**: governance votes can trigger escalation at any level
- **lex-privatecore**: level 4 escalation triggers cryptographic erasure of memory traces
- **lex-mesh**: level 1 (mesh_isolation) disconnects the agent from the mesh network
- **lex-tick**: emergency trigger `:extinction_protocol` in tick causes immediate `full_active` mode

## Development Notes

- Authority validation is exact symbol match — no inheritance or permission hierarchies
- De-escalation does not require matching the authority that escalated; any authority with deescalation rights at the current level could de-escalate (currently authority is just passed through for logging, not validated against who escalated)
- Level 4 cannot be reversed via `deescalate` due to the `:irreversible` check
- History is not capped in the current implementation
- `ProtocolMonitor` runs even when the protocol is inactive (level 0, `active: false`), providing a steady heartbeat log at debug level
