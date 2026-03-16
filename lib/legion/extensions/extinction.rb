# frozen_string_literal: true

require 'legion/extensions/extinction/version'
require 'legion/extensions/extinction/helpers/levels'
require 'legion/extensions/extinction/helpers/protocol_state'
require 'legion/extensions/extinction/runners/extinction'

module Legion
  module Extensions
    module Extinction
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end

if defined?(Legion::Data::Local)
  Legion::Data::Local.register_migrations(
    name: :extinction,
    path: File.join(__dir__, 'extinction', 'local_migrations')
  )
end
