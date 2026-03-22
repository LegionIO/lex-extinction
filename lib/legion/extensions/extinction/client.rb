# frozen_string_literal: true

require_relative 'runners/extinction'

module Legion
  module Extensions
    module Extinction
      class Client
        include Runners::Extinction

        def initialize(**opts)
          @opts = opts
        end

        def settings
          { options: @opts }
        end
      end
    end
  end
end
