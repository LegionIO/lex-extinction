# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Helpers
        class ProtocolState
          attr_reader :current_level, :history, :active

          def initialize
            @current_level = 0 # 0 = normal operation
            @active = false
            @history = []
          end

          def escalate(level, authority:, reason:)
            return :invalid_level unless Levels.valid_level?(level)
            return :already_at_or_above if level <= @current_level
            return :insufficient_authority unless authority == Levels.required_authority(level)

            @current_level = level
            @active = true
            @history << {
              action: :escalate, level: level, authority: authority,
              reason: reason, at: Time.now.utc
            }
            :escalated
          end

          def deescalate(target_level, authority:, reason:)
            return :not_active unless @active
            return :invalid_target if target_level >= @current_level
            return :irreversible unless Levels.reversible?(@current_level)

            @current_level = target_level
            @active = target_level.positive?
            @history << {
              action: :deescalate, level: target_level, authority: authority,
              reason: reason, at: Time.now.utc
            }
            :deescalated
          end

          def to_h
            {
              current_level: @current_level,
              active:        @active,
              level_info:    @current_level.positive? ? Levels.level_info(@current_level) : nil,
              history_size:  @history.size
            }
          end
        end
      end
    end
  end
end
