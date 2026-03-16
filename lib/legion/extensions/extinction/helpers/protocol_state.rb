# frozen_string_literal: true

require 'json'

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
            load_from_local
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

          def save_to_local
            return unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?

            row = {
              id:            1,
              current_level: @current_level,
              active:        @active,
              history:       ::JSON.dump(@history.map { |h| h.merge(at: h[:at].to_s) }),
              updated_at:    Time.now.utc
            }
            db = Legion::Data::Local.connection
            if db[:extinction_state].where(id: 1).count.positive?
              db[:extinction_state].where(id: 1).update(row.reject { |k, _| k == :id })
            else
              db[:extinction_state].insert(row)
            end
          rescue StandardError
            nil
          end

          private

          def load_from_local
            return unless defined?(Legion::Data::Local) && Legion::Data::Local.connected?

            row = Legion::Data::Local.connection[:extinction_state].where(id: 1).first
            return unless row

            db_level = row[:current_level].to_i
            @current_level = [db_level, @current_level].max
            @active = row[:active] == true || row[:active] == 1
            @history = parse_history(row[:history])
          rescue StandardError
            nil
          end

          def parse_history(raw)
            return [] if raw.nil? || raw.empty?

            parsed = ::JSON.parse(raw, symbolize_names: true)
            parsed.map do |h|
              h.merge(
                action:    h[:action].to_sym,
                authority: h[:authority].to_sym,
                at:        Time.parse(h[:at].to_s)
              )
            end
          rescue StandardError
            []
          end
        end
      end
    end
  end
end
