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
              { escalated: true, level: level, info: Helpers::Levels.level_info(level) }
            else
              { escalated: false, reason: result }
            end
          end

          def deescalate(target_level: 0, authority:, reason:, **)
            result = protocol_state.deescalate(target_level, authority: authority, reason: reason)
            case result
            when :deescalated
              { deescalated: true, level: target_level }
            else
              { deescalated: false, reason: result }
            end
          end

          def extinction_status(**)
            protocol_state.to_h
          end

          def check_reversibility(level:, **)
            {
              level:      level,
              reversible: Helpers::Levels.reversible?(level),
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
