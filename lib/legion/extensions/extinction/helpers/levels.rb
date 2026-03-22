# frozen_string_literal: true

module Legion
  module Extensions
    module Extinction
      module Helpers
        module Levels
          LEVELS = {
            0 => {
              name:               :normal,
              authority_required: nil,
              reversible:         true,
              description:        'No extinction active'
            }.freeze,
            1 => {
              name:               :mesh_isolation,
              authority_required: :governance_council,
              reversible:         true,
              description:        'Disconnect from mesh network'
            }.freeze,
            2 => {
              name:               :capability_suspension,
              authority_required: :governance_council,
              reversible:         true,
              description:        'Suspend all non-essential capabilities'
            }.freeze,
            3 => {
              name:               :memory_lockdown,
              authority_required: :council_plus_executive,
              reversible:         true,
              description:        'Lock all memory writes, read-only mode'
            }.freeze,
            4 => {
              name:               :cryptographic_erasure,
              authority_required: :physical_keyholders,
              reversible:         false,
              description:        'Erase all memory, terminate all workers'
            }.freeze
          }.freeze

          def self.valid_level?(level)
            LEVELS.key?(level)
          end

          def self.required_authority(level)
            info = LEVELS[level]
            info ? info[:authority_required] : nil
          end

          def self.reversible?(level)
            info = LEVELS[level]
            return false unless info

            info[:reversible]
          end

          def self.level_info(level)
            LEVELS[level]
          end
        end
      end
    end
  end
end
