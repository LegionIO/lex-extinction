# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Settings
        DEFAULTS = {
          enabled:               true,
          governance_required:   true,
          stale_threshold_hours: 24,
          monitor_interval:      300,
          archive_on_escalate:   true,
          max_history:           500
        }.freeze

        def self.setting(key)
          if defined?(Legion::Settings) && Legion::Settings[:extinction]
            Legion::Settings[:extinction].fetch(key, DEFAULTS[key])
          else
            DEFAULTS[key]
          end
        end
      end
    end
  end
end
