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

          def check_reversibility(level:, **)
            reversible = Helpers::Levels.reversible?(level)
            Legion::Logging.debug "[extinction] reversibility: level=#{level} reversible=#{reversible}"
            {
              level:      level,
              reversible: reversible,
              authority:  Helpers::Levels.required_authority(level)
            }
          end

          private

          def protocol_state
            @protocol_state ||= Helpers::ProtocolState.new
          end
        end
      end
    end
  end
end
