# frozen_string_literal: true

require_relative 'levels'

module Legion
  module Extensions
    module Extinction
      module Helpers
        class ProtocolState
          MAX_HISTORY = 500

          attr_reader :history

          def initialize
            @current_level = 0
            @history       = []
            @store         = {}
            load_from_local
          end

          def escalate(level:, authority:, reason:)
            return { success: false, reason: :invalid_level } unless Levels.valid_level?(level)
            return { success: false, reason: :invalid_escalation } if level <= @current_level

            required = Levels.required_authority(level)
            return { success: false, reason: :insufficient_authority, required: required, provided: authority } if required && authority != required

            previous = @current_level
            @current_level = level
            record_history(action: :escalate, from: previous, to: level, authority: authority, reason: reason)
            trim_history
            save_to_local

            { success: true, previous_level: previous, current_level: level }
          end

          def deescalate(target_level:, authority:, reason:)
            return { success: false, reason: :invalid_level } unless Levels.valid_level?(target_level)
            return { success: false, reason: :invalid_deescalation } if target_level >= @current_level

            return { success: false, reason: :not_reversible } unless Levels.reversible?(@current_level)

            required = Levels.required_authority(@current_level)
            return { success: false, reason: :insufficient_authority, required: required, provided: authority } if required && authority != required

            previous = @current_level
            @current_level = target_level
            record_history(action: :deescalate, from: previous, to: target_level, authority: authority,
                           reason: reason)
            trim_history
            save_to_local

            { success: true, previous_level: previous, current_level: target_level }
          end

          def to_h
            {
              current_level: @current_level,
              level_name:    Levels.level_info(@current_level)&.dig(:name),
              reversible:    Levels.reversible?(@current_level),
              history_count: @history.size,
              last_change:   @history.last
            }
          end

          private

          def record_history(action:, from:, to:, authority:, reason:)
            @history << {
              action:    action,
              from:      from,
              to:        to,
              authority: authority,
              reason:    reason,
              at:        Time.now.utc.iso8601
            }
          end

          def trim_history
            max = defined?(Legion::Extensions::Extinction::Settings) ? Legion::Extensions::Extinction::Settings.setting(:max_history) : MAX_HISTORY
            return unless @history.size > max

            @history.shift(@history.size - max)
          end

          def save_to_local
            data = { current_level: @current_level, history: @history }
            if defined?(Legion::Data::Local)
              Legion::Data::Local.set('extinction:protocol_state', data)
            else
              @store[:protocol_state] = data
            end
          rescue StandardError => e
            Legion::Logging.warn "[extinction] protocol_state save failed: #{e.message}" if defined?(Legion::Logging)
          end

          def load_from_local
            data = if defined?(Legion::Data::Local)
                     Legion::Data::Local.get('extinction:protocol_state')
                   else
                     @store[:protocol_state]
                   end
            return unless data

            @current_level = data[:current_level] || data['current_level'] || 0
            raw_history    = data[:history] || data['history'] || []
            @history       = raw_history
          rescue StandardError => e
            Legion::Logging.warn "[extinction] protocol_state load failed: #{e.message}" if defined?(Legion::Logging)
          end
        end
      end
    end
  end
end
