# frozen_string_literal: true

require_relative 'extinction/version'
require_relative 'extinction/settings'
require_relative 'extinction/helpers/levels'
require_relative 'extinction/helpers/protocol_state'
require_relative 'extinction/helpers/archiver'
require_relative 'extinction/runners/extinction'

require_relative 'extinction/actors/protocol_monitor' if defined?(Legion::Extensions::Actors::Every)

module Legion
  module Extensions
    module Extinction
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)

      def self.data_required?
        false
      end

      def self.remote_invocable?
        false
      end
    end
  end
end
