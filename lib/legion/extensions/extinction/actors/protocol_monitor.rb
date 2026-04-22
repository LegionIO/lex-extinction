# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Actor
        if defined?(Legion::Extensions::Actors::Every)
          class ProtocolMonitor < Legion::Extensions::Actors::Every # rubocop:disable Legion/Extension/EveryActorRequiresTime
            def runner_class
              Legion::Extensions::Extinction::Runners::Extinction
            end

            def runner_function
              'monitor_protocol'
            end

            def time
              Legion::Extensions::Extinction::Settings.setting(:monitor_interval)
            rescue StandardError => e
              log.debug("monitor_interval setting unavailable: #{e.message}")
              300
            end

            def run_now?
              false
            end

            def use_runner?
              true
            end

            def check_subtask?
              false
            end

            def generate_task?
              false
            end

            private

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
end
