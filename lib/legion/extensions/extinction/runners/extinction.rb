# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Runners
        module Extinction
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def escalate(level:, authority:, reason:, **)
            result = protocol_state.escalate(level, authority: authority, reason: reason)
            case result
            when :escalated
              info = Helpers::Levels.level_info(level)
              Legion::Logging.warn "[extinction] ESCALATED: level=#{level} name=#{info[:name]} authority=#{authority} reason=#{reason}"
              enforce_escalation_effects(level)
              emit_escalation_event(level, authority, reason)
              { escalated: true, level: level, info: info }
            else
              Legion::Logging.debug "[extinction] escalation denied: level=#{level} reason=#{result}"
              { escalated: false, reason: result }
            end
          end

          def deescalate(authority:, reason:, target_level: 0, **)
            result = protocol_state.deescalate(target_level, authority: authority, reason: reason)
            case result
            when :deescalated
              Legion::Logging.info "[extinction] de-escalated: target=#{target_level} authority=#{authority} reason=#{reason}"
              { deescalated: true, level: target_level }
            else
              Legion::Logging.debug "[extinction] de-escalation denied: target=#{target_level} reason=#{result}"
              { deescalated: false, reason: result }
            end
          end

          def extinction_status(**)
            status = protocol_state.to_h
            Legion::Logging.debug "[extinction] status: level=#{status[:current_level]} active=#{status[:active]}"
            status
          end

          def monitor_protocol(**)
            status = protocol_state.to_h
            level = status[:current_level]

            if level.positive?
              Legion::Logging.warn "[extinction] ACTIVE: level=#{level} active=#{status[:active]}"
              detect_stale_escalation(level)
            else
              Legion::Logging.debug '[extinction] status: level=0 active=false'
            end

            status
          end

          def check_reversibility(level:, **)
            reversible = Helpers::Levels.reversible?(level)
            Legion::Logging.debug "[extinction] reversibility: level=#{level} reversible=#{reversible}"
            {
              level:      level,
              reversible: reversible,
              authority:  Helpers::Levels.required_authority(level)
            }
          end

          STALE_ESCALATION_THRESHOLD = 86_400

          private

          def enforce_escalation_effects(level)
            if level >= 1 && defined?(Legion::Extensions::Mesh::Runners::Mesh)
              Legion::Extensions::Mesh::Runners::Mesh.disconnect rescue nil # rubocop:disable Style/RescueModifier
              Legion::Logging.warn '[extinction] mesh isolation enforced'
            end

            return unless level == 4

            if defined?(Legion::Extensions::Privatecore::Runners::Privatecore)
              Legion::Extensions::Privatecore::Runners::Privatecore.erase_all rescue nil # rubocop:disable Style/RescueModifier
              Legion::Logging.warn '[extinction] cryptographic erasure triggered'
            end

            return unless defined?(Legion::Data::Model::DigitalWorker)

            begin
              Legion::Data::Model::DigitalWorker.where(lifecycle_state: 'active').update(
                lifecycle_state: 'terminated', updated_at: Time.now.utc
              )
            rescue StandardError
              nil
            end
            Legion::Logging.warn '[extinction] all active workers terminated'
          end

          def emit_escalation_event(level, authority, reason)
            return unless defined?(Legion::Events)

            info = Helpers::Levels.level_info(level)
            Legion::Events.emit("extinction.#{info[:name]}", {
                                  level: level, authority: authority, reason: reason, at: Time.now.utc
                                })
          end

          def detect_stale_escalation(level)
            last_escalation = protocol_state.history.select { |h| h[:action] == :escalate }.last
            return unless last_escalation && (Time.now.utc - last_escalation[:at]) > STALE_ESCALATION_THRESHOLD

            Legion::Logging.warn "[extinction] STALE: level=#{level} has been active > 24 hours"
            return unless defined?(Legion::Events)

            Legion::Events.emit('extinction.stale_escalation', {
                                  level: level, since: last_escalation[:at],
                                  hours: ((Time.now.utc - last_escalation[:at]) / 3600).round(1)
                                })
          end

          def protocol_state
            @protocol_state ||= Helpers::ProtocolState.new
          end
        end
      end
    end
  end
end
