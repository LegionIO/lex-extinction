# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Extinction
      module Actor
        class ProtocolMonitor < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::Extinction::Runners::Extinction
          end

          def runner_function
            'monitor_protocol'
          end

          def time
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
        end
      end
    end
  end
end
