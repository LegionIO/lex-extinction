# frozen_string_literal: true

require_relative 'lib/legion/extensions/extinction/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-extinction'
  spec.version       = Legion::Extensions::Extinction::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matt@esity.io']
  spec.summary       = 'Agent lifecycle termination protocol for LegionIO'
  spec.description   = 'Five-level extinction protocol with archival, audit trail, governance gates, and configurable settings'
  spec.homepage      = 'https://github.com/LegionIO/lex-extinction'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-extinction'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-extinction'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-extinction'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-extinction/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'legion-cache', '>= 1.3.11'
  spec.add_dependency 'legion-crypt', '>= 1.4.9'
  spec.add_dependency 'legion-data', '>= 1.4.17'
  spec.add_dependency 'legion-json', '>= 1.2.1'
  spec.add_dependency 'legion-logging', '>= 1.3.2'
  spec.add_dependency 'legion-settings', '>= 1.3.14'
  spec.add_dependency 'legion-transport', '>= 1.3.9'

  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
