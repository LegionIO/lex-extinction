# lex-extinction: Containment and Termination Protocol

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Five-level safety containment ladder for LegionIO agents. Manages escalation and de-escalation through isolation, capability suspension, memory lockdown, and irreversible cryptographic erasure. Authority-gated at each level with audit trail and optional governance integration.

## Gem Info

- **Gem name**: `lex-extinction`
- **Version**: `0.2.2`
- **Module**: `Legion::Extensions::Extinction`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/extinction/
  version.rb
  settings.rb                         # Settings.setting(:key) — reads from Legion::Settings[:extinction]
  client.rb                           # Client — includes Runners::Extinction
  helpers/
    levels.rb                         # LEVELS hash (0–4), valid_level?, required_authority, reversible?, level_info
    protocol_state.rb                 # ProtocolState class — current level, history (max 500), persist to Data::Local
    archiver.rb                       # Archiver class — archive agent records with timestamp and metadata
  runners/
    extinction.rb                     # escalate, deescalate, extinction_status, monitor_protocol,
                                      #   archive_agent, full_termination
  actors/
    protocol_monitor.rb               # Every (monitor_interval, default 300s): monitor_protocol
spec/
```

## Five Containment Levels

| Level | Name | Authority Required | Reversible |
|-------|------|--------------------|------------|
| 0 | `:normal` | none | yes |
| 1 | `:mesh_isolation` | `:governance_council` | yes |
| 2 | `:capability_suspension` | `:governance_council` | yes |
| 3 | `:memory_lockdown` | `:council_plus_executive` | yes |
| 4 | `:cryptographic_erasure` | `:physical_keyholders` | **no** |

## Runner Methods

All in `Runners::Extinction`:

| Method | Key Args | Returns |
|---|---|---|
| `escalate` | `level:, authority:, reason:` | `{ success:, previous_level:, current_level: }` |
| `deescalate` | `target_level:, authority:, reason:` | `{ success:, previous_level:, current_level: }` |
| `extinction_status` | — | `{ success:, state:, level_info: }` |
| `monitor_protocol` | — | `{ success:, state:, stale:, checked_at: }` |
| `archive_agent` | `agent_id:, reason:, metadata: {}` | `{ success:, archive: }` |
| `full_termination` | `agent_id:, authority:, reason:` | governance check → archive → escalate(4) |

## ProtocolState

- Persists to `Legion::Data::Local` when available; falls back to in-memory `@store`
- History capped at `MAX_HISTORY` (500) or `Settings.setting(:max_history)`
- `escalate` requires `level > current_level`; `deescalate` requires `target_level < current_level` AND `reversible?` on current level
- Both validate authority match against `Levels.required_authority`

## Settings

All under `extinction` key:

```yaml
extinction:
  governance_required: true         # whether full_termination checks lex-governance
  archive_on_escalate: false        # auto-archive when escalating to level >= 3
  stale_threshold_hours: 24         # hours before monitor_protocol reports stale
  monitor_interval: 300             # seconds between ProtocolMonitor ticks
  max_history: 500                  # max entries in ProtocolState history
```

## Integration Points

- **lex-agentic-defense**: `Defense::Extinction` sub-module delegates to this gem's runner
- **lex-privatecore**: level 4 triggers `Privatecore::Client#full_erasure`
- **lex-governance**: `full_termination` checks `Governance::Runners::Governance.review_transition`
- **LegionIO Lifecycle**: `lifecycle.rb` maps `EXTINCTION_MAPPING` transitions to `escalate` calls
- **Legion::Data::Local**: state persistence (fallback to in-memory)
- **Legion::Events**: fires `extinction.escalated` and `extinction.deescalated` events
- **Legion::Extensions::Audit**: `record_audit` for every escalation/de-escalation/termination

## Actor: ProtocolMonitor

`Every` actor. Fires `monitor_protocol` at `monitor_interval` (default 300s). `run_now?` is false. Overrides `runner_class` to return `self.class` (self-contained actor pattern).

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
