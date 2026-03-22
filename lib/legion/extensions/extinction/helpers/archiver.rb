# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Helpers
        class Archiver
          def initialize
            @archives = []
          end

          def archive(agent_id:, reason:, metadata: {})
            level = current_protocol_level
            record = {
              agent_id:       agent_id,
              reason:         reason,
              metadata:       metadata,
              level:          level,
              archived_at:    Time.now.utc.iso8601,
              state_snapshot: capture_state_snapshot
            }

            persist_archive(record)
            record
          end

          def all_archives
            @archives.dup
          end

          private

          def current_protocol_level
            0
          end

          def capture_state_snapshot
            snapshot = {}
            snapshot[:mesh_connected] = true if defined?(Legion::Extensions::Mesh)
            snapshot[:privatecore_active] = true if defined?(Legion::Extensions::Privatecore)
            snapshot
          end

          def persist_archive(record)
            if defined?(Legion::Data::Local)
              key = "extinction:archive:#{record[:agent_id]}:#{record[:archived_at]}"
              Legion::Data::Local.set(key, record)
            end
            @archives << record
          rescue StandardError => e
            Legion::Logging.warn "[extinction] archive persist failed: #{e.message}" if defined?(Legion::Logging)
            @archives << record
          end
        end
      end
    end
  end
end
