# frozen_string_literal: true

require_relative 'runners/extinction'

module Legion
  module Extensions
    module Extinction
      class Client
        # The runner module uses `extend self` which creates both module functions
        # (for the runner framework) and instance methods (copied by this include).
        # Instance variables (@protocol_state, @archiver) resolve per-Client instance,
        # giving each client its own isolated protocol state.
        include Runners::Extinction

        def initialize(**opts)
          @opts = opts
        end

        def settings
          { options: @opts }
        end

        # Override runner methods so that per-instance @opts (e.g. timeout:)
        # are threaded through as defaults on every call.
        def escalate(**)
          super(**@opts, **)
        end

        def deescalate(**)
          super(**@opts, **)
        end

        def extinction_status(**)
          super(**@opts, **)
        end

        def monitor_protocol(**)
          super(**@opts, **)
        end

        def archive_agent(**)
          super(**@opts, **)
        end

        def full_termination(**)
          super(**@opts, **)
        end
      end
    end
  end
end
