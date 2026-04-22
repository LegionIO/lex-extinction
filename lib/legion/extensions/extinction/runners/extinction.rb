# frozen_string_literal: true

require_relative '../helpers/levels'
require_relative '../helpers/protocol_state'
require_relative '../helpers/archiver'
require_relative '../settings'

module Legion
  module Extensions
    module Extinction
      module Runners
        module Extinction
          extend self

          def escalate(level:, authority:, reason:, **)
            result = protocol_state.escalate(level: level, authority: authority, reason: reason)
            return result unless result[:success]

            enforce_escalation_effects(level)
            emit_escalation_event(level, authority, reason)
            record_audit(action: :escalate, details: { level: level, authority: authority, reason: reason })

            if Legion::Extensions::Extinction::Settings.setting(:archive_on_escalate) && level >= 3
              archive_agent(agent_id: 'self', reason: "auto-archive at level #{level}", metadata: { triggered_by: :escalate })
            end

            result
          end

          def deescalate(target_level:, authority:, reason:, **)
            result = protocol_state.deescalate(target_level: target_level, authority: authority, reason: reason)
            return result unless result[:success]

            emit_deescalation_event(target_level, authority, reason)
            record_audit(action:  :deescalate,
                         details: { target_level: target_level, authority: authority, reason: reason })

            result
          end

          def extinction_status(**)
            state = protocol_state.to_h
            level_info = Helpers::Levels.level_info(state[:current_level])
            { success: true, state: state, level_info: level_info }
          end

          def monitor_protocol(**)
            state = protocol_state.to_h
            last_change = state[:last_change]
            stale       = false

            if last_change
              threshold_hours = Legion::Extensions::Extinction::Settings.setting(:stale_threshold_hours)
              changed_at      = Time.parse(last_change[:at]) rescue nil # rubocop:disable Style/RescueModifier
              stale           = changed_at && (Time.now.utc - changed_at) > (threshold_hours * 3600)
            end

            {
              success:    true,
              state:      state,
              stale:      stale,
              checked_at: Time.now.utc.iso8601
            }
          end

          def archive_agent(agent_id:, reason:, metadata: {}, **)
            record = archiver.archive(agent_id: agent_id, reason: reason, metadata: metadata)
            record_audit(action: :archive, details: { agent_id: agent_id, reason: reason })
            { success: true, archive: record }
          end

          def full_termination(agent_id:, authority:, reason:, **)
            gate = governance_check(authority: authority)
            return gate unless gate[:success]

            archive_result = archive_agent(agent_id: agent_id, reason: reason,
                                           metadata: { termination: true, authority: authority })
            return archive_result unless archive_result[:success]

            escalate_result = escalate(level: 4, authority: authority, reason: reason)
            return escalate_result unless escalate_result[:success]

            record_audit(action: :full_termination, details: { agent_id: agent_id, authority: authority, reason: reason })
            { success: true, agent_id: agent_id, archive: archive_result[:archive], terminated_at: Time.now.utc.iso8601 }
          end

          private

          def protocol_state
            @protocol_state ||= Helpers::ProtocolState.new
          end

          def archiver
            @archiver ||= Helpers::Archiver.new
          end

          def enforce_escalation_effects(level)
            reason = "escalation to level #{level}"
            case level
            when 1
              # Mesh disconnect depends on lex-mesh responding to the extinction.level_1 event
              log.info '[extinction] mesh isolation: disconnecting from mesh'
              emit_level_event(level, reason)
            when 2
              # Capability suspension depends on extensions responding to the extinction.level_2 event
              log.warn '[extinction] capability suspension: suspending non-essential capabilities'
              emit_level_event(level, reason)
            when 3
              # Memory write lock depends on lex-privatecore responding to the extinction.level_3 event
              log.warn '[extinction] memory lockdown: locking all memory writes'
              log.warn '[extinction] notifying privatecore of memory lockdown' if defined?(Legion::Extensions::Privatecore)
              emit_level_event(level, reason)
            when 4
              log.warn '[extinction] cryptographic erasure: beginning irreversible termination'
              emit_level_event(level, reason)
              trigger_cryptographic_erasure
            end
          end

          def trigger_cryptographic_erasure
            if defined?(Legion::Extensions::Privatecore::Runners::Privatecore)
              log.info '[extinction] invoking privatecore cryptographic erasure'
              client = Legion::Extensions::Privatecore::Client.new if defined?(Legion::Extensions::Privatecore::Client)
              client&.full_erasure(traces: [], agent_id: 'self')
            end
            log.warn '[extinction] cryptographic erasure complete'
          rescue StandardError => e
            log.error "[extinction] cryptographic erasure FAILED: #{e.message}"
            raise
          end

          def emit_escalation_event(level, authority, reason)
            payload = { level: level, authority: authority, reason: reason, at: Time.now.utc.iso8601 }
            Legion::Events.emit('extinction.escalated', payload) if defined?(Legion::Events)
          rescue StandardError => e
            log.warn "[extinction] event emit failed: #{e.message}"
          end

          def emit_deescalation_event(target_level, authority, reason)
            payload = { target_level: target_level, authority: authority, reason: reason, at: Time.now.utc.iso8601 }
            Legion::Events.emit('extinction.deescalated', payload) if defined?(Legion::Events)
          rescue StandardError => e
            log.warn "[extinction] event emit failed: #{e.message}"
          end

          def emit_level_event(level, reason)
            return unless defined?(Legion::Events)

            log.info "[extinction] emitting extinction.level_#{level} event"
            Legion::Events.emit("extinction.level_#{level}", { level: level, reason: reason, at: Time.now.utc.iso8601 })
          rescue StandardError => e
            log.error "[extinction] level event emit failed: #{e.message}"
          end

          def governance_check(authority:, level: 4, _reason: nil)
            return { success: true } unless Legion::Extensions::Extinction::Settings.setting(:governance_required)
            return { success: true } unless defined?(Legion::Extensions::Agentic::Social::Governance)

            log.info "[extinction] governance check: authority=#{authority} level=#{level}"
            review = Legion::Extensions::Agentic::Social::Governance::Runners::Governance.validate_action(
              action: "extinction_escalate_#{level}"
            )

            if review[:allowed]
              { success: true }
            else
              { success: false, reason: :governance_blocked, details: review[:reasons] }
            end
          rescue StandardError => e
            log.error "[extinction] governance check failed: #{e.message}"
            { success: false, reason: 'governance unavailable' }
          end

          def record_audit(action:, details: {})
            return unless defined?(Legion::Extensions::Audit::Runners::Audit)

            Legion::Extensions::Audit::Runners::Audit.record(
              entity_type: 'extinction',
              entity_id:   'protocol',
              action:      action,
              details:     details
            )
          rescue StandardError => e
            log.warn "[extinction] audit record failed: #{e.message}"
          end

          def log
            return Legion::Logging if defined?(Legion::Logging)

            @log ||= Object.new.tap do |nl|
              %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
            end
          end
        end
      end
    end
  end
end
