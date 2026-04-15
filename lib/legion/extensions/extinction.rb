# frozen_string_literal: true

require_relative 'extinction/version'
require_relative 'extinction/settings'
require_relative 'extinction/helpers/levels'
require_relative 'extinction/helpers/protocol_state'
require_relative 'extinction/helpers/archiver'
require_relative 'extinction/runners/extinction'

require_relative 'extinction/actors/protocol_monitor'

module Legion
  module Extensions
    module Extinction
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)

      def self.data_required? = false

      def self.remote_invocable? = false

      def self.mcp_tools?
        false
      end

      def self.mcp_tools_deferred?
        false
      end

      def self.transport_required?
        false
      end
    end
  end
end
