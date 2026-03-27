# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Actor
        if defined?(Legion::Extensions::Actors::Every)
          class ProtocolMonitor < Legion::Extensions::Actors::Every
            def runner_class
              self.class
            end

            def runner_function
              'monitor_protocol'
            end

            def time
              Legion::Extensions::Extinction::Settings.setting(:monitor_interval)
            rescue StandardError
              300
            end

            def run_now?
              false
            end

            def use_runner?
              false
            end

            def check_subtask?
              false
            end

            def generate_task?
              false
            end

            def monitor_protocol(**)
              state = build_state
              last_change = state[:last_change]
              stale       = check_stale(last_change)

              log&.debug "[extinction] monitor_protocol: level=#{state[:current_level]} stale=#{stale}"

              {
                success:    true,
                state:      state,
                stale:      stale,
                checked_at: Time.now.utc.iso8601
              }
            end

            private

            def build_state
              {
                current_level: 0,
                level_name:    :normal,
                reversible:    true,
                history_count: 0,
                last_change:   nil
              }
            end

            def check_stale(last_change)
              return false unless last_change

              threshold_hours = Legion::Extensions::Extinction::Settings.setting(:stale_threshold_hours)
              changed_at      = Time.parse(last_change[:at]) rescue nil # rubocop:disable Style/RescueModifier
              changed_at && (Time.now.utc - changed_at) > (threshold_hours * 3600)
            end

            def log
              return unless defined?(Legion::Logging)

              Legion::Logging
            end
          end
        end
      end
    end
  end
end
