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
            case level
            when 1
              Legion::Logging.info '[extinction] mesh isolation: disconnecting from mesh' if defined?(Legion::Extensions::Mesh) && defined?(Legion::Logging)
            when 2
              Legion::Logging.info '[extinction] capability suspension: suspending non-essential capabilities' if defined?(Legion::Logging)
            when 3
              Legion::Logging.warn '[extinction] memory lockdown: locking all memory writes' if defined?(Legion::Logging)
              if defined?(Legion::Extensions::Privatecore) && defined?(Legion::Logging)
                Legion::Logging.warn '[extinction] notifying privatecore of memory lockdown'
              end
            when 4
              Legion::Logging.warn '[extinction] cryptographic erasure: beginning irreversible termination' if defined?(Legion::Logging)
              trigger_cryptographic_erasure
            end
          end

          def trigger_cryptographic_erasure
            if defined?(Legion::Extensions::Privatecore::Runners::Privatecore)
              client = Legion::Extensions::Privatecore::Client.new if defined?(Legion::Extensions::Privatecore::Client)
              client&.full_erasure(traces: [], agent_id: 'self')
            end
            Legion::Logging.warn '[extinction] cryptographic erasure complete' if defined?(Legion::Logging)
          end

          def emit_escalation_event(level, authority, reason)
            payload = { level: level, authority: authority, reason: reason, at: Time.now.utc.iso8601 }
            Legion::Events.emit('extinction.escalated', payload) if defined?(Legion::Events)
          rescue StandardError => e
            Legion::Logging.warn "[extinction] event emit failed: #{e.message}" if defined?(Legion::Logging)
          end

          def emit_deescalation_event(target_level, authority, reason)
            payload = { target_level: target_level, authority: authority, reason: reason, at: Time.now.utc.iso8601 }
            Legion::Events.emit('extinction.deescalated', payload) if defined?(Legion::Events)
          rescue StandardError => e
            Legion::Logging.warn "[extinction] event emit failed: #{e.message}" if defined?(Legion::Logging)
          end

          def governance_check(authority:, _reason: nil)
            return { success: true } unless Legion::Extensions::Extinction::Settings.setting(:governance_required)
            return { success: true } unless defined?(Legion::Extensions::Governance)

            review = Legion::Extensions::Governance::Runners::Governance.review_transition(
              worker_id:    'extinction',
              from_state:   'active',
              to_state:     'terminated',
              principal_id: authority.to_s,
              worker_owner: nil
            )

            if review[:allowed]
              { success: true }
            else
              { success: false, reason: :governance_blocked, details: review[:reasons] }
            end
          rescue StandardError => e
            Legion::Logging.warn "[extinction] governance check failed: #{e.message}" if defined?(Legion::Logging)
            { success: true }
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
            Legion::Logging.warn "[extinction] audit record failed: #{e.message}" if defined?(Legion::Logging)
          end
        end
      end
    end
  end
end
