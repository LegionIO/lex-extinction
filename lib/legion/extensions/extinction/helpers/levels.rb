# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Helpers
        module Levels
          # Four escalation levels (spec: extinction-protocol-spec.md)
          ESCALATION_LEVELS = {
            1 => { name: :mesh_isolation,       reversible: true,  authority: :governance_council },
            2 => { name: :forced_sentinel,      reversible: true,  authority: :governance_council },
            3 => { name: :full_suspension,       reversible: true,  authority: :council_plus_executive },
            4 => { name: :cryptographic_erasure, reversible: false, authority: :physical_keyholders }
          }.freeze

          VALID_LEVELS = [1, 2, 3, 4].freeze

          module_function

          def valid_level?(level)
            VALID_LEVELS.include?(level)
          end

          def level_info(level)
            ESCALATION_LEVELS[level]
          end

          def reversible?(level)
            ESCALATION_LEVELS.dig(level, :reversible) || false
          end

          def required_authority(level)
            ESCALATION_LEVELS.dig(level, :authority)
          end
        end
      end
    end
  end
end
