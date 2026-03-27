# Changelog

## [0.2.8] - 2026-03-27

### Fixed
- Capture exception in `ProtocolMonitor#time` rescue block (`rescue StandardError => e`) and log debug message to satisfy CI Rescue Logging lint

## [0.2.7] - 2026-03-27

### Fixed
- Replace `log&.method` safe-navigation calls with `log.method` so CI "Rescue Logging" regex (`\blog\.`) matches all log calls in rescue blocks

## [0.2.6] - 2026-03-27

### Fixed
- Replace direct `Legion::Logging.*` calls with `log&.*` (per-extension tagged logger) in all lib files to pass Helper Migration CI lint

## [0.2.5] - 2026-03-27

### Fixed
- ProtocolMonitor actor: `module Actors` → `module Actor` to match framework convention

## [0.2.4] - 2026-03-27

### Fixed
- `data_required?` and `remote_invocable?` defined as proper `def self.` methods instead of calling the method with an argument

## [0.2.3] - 2026-03-26

### Changed
- fix remote_invocable? and data_required? to use class methods for local dispatch

## [0.2.2] - 2026-03-22

### Changed
- Add legion-logging, legion-settings, legion-json, legion-cache, legion-crypt, legion-data, and legion-transport as runtime dependencies
- Update spec_helper with real sub-gem helper stubs replacing hand-rolled Legion::Logging stub

## [0.2.0] - 2026-03-22

### Added
- Initial release of lex-extinction: five-level agent lifecycle termination protocol
- `Helpers::Levels` with frozen LEVELS constant, authority and reversibility lookups
- `Helpers::ProtocolState` state machine with escalate/deescalate, history (capped at 500), and optional local persistence
- `Helpers::Archiver` for capturing agent state before termination, with optional Legion::Data::Local persistence
- `Runners::Extinction` module with escalate, deescalate, extinction_status, monitor_protocol, archive_agent, and full_termination
- `Actors::ProtocolMonitor` self-contained Every actor (300s interval, guarded by defined?(Legion::Extensions::Actors::Every))
- `Client` standalone class including all runner methods
- `Settings` module with DEFAULTS hash and settings accessor with Legion::Settings fallback
- Governance gate on full_termination (delegates to Legion::Extensions::Governance when loaded)
- Audit trail via Legion::Extensions::Audit when loaded
- Event emission via Legion::Events when loaded
- Side effects per escalation level: mesh isolation (1), capability suspension (2), memory lockdown (3), cryptographic erasure (4)
- Full guard pattern for all optional dependencies
- 47 RSpec examples, 0 failures
