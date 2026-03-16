# frozen_string_literal: true

require_relative 'lib/legion/extensions/extinction/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-extinction'
  spec.version       = Legion::Extensions::Extinction::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Extinction'
  spec.description   = 'Escalation and extinction protocol (4 levels) for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-extinction'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-extinction'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-extinction'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-extinction'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-extinction/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-extinction.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
