# Changelog

## [0.2.0] - 2026-03-16

### Fixed
- State now persisted to local store after every escalate/deescalate (was only loaded, never saved)
- History capped at 500 entries (was unbounded)
- Deescalate now validates authority against current level (was accepting any authority)

### Added
- Level 1+ enforcement: mesh isolation via lex-mesh disconnect (guarded)
- Level 4 enforcement: cryptographic erasure via lex-privatecore + worker termination (guarded)
- `monitor_protocol` runner method with stale escalation detection (24hr threshold)
- Event emission on escalation (`extinction.<level_name>`) and stale detection (`extinction.stale_escalation`)

### Changed
- `ProtocolMonitor` actor now calls `monitor_protocol` instead of `extinction_status`

## [0.1.1] - 2026-03-14

### Added
- `ProtocolMonitor` actor (Every 300s): periodic monitoring of extinction protocol state for active containment awareness via `extinction_status` in `runners/extinction.rb`

## [0.1.0] - 2026-03-13

### Added
- Initial release
