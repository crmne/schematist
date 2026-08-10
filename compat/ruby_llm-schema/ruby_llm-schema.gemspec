# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'ruby_llm-schema'
  # Hardcoded: this gem forwards to schematist and is not expected to be released again.
  spec.version       = '0.5.0'
  spec.authors       = ['Daniel Friis', 'Carmine Paolino']
  spec.email         = ['d@friis.me', 'carmine@paolino.me']

  spec.summary       = 'Deprecated. ruby_llm-schema is now schematist.'
  spec.description   = 'Forwards RubyLLM::Schema to Schematist::Schema. Depend on schematist instead.'
  spec.homepage      = 'https://github.com/crmne/schematist#migrating-from-ruby_llm-schema'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.3')

  source_uri = 'https://github.com/crmne/schematist'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = source_uri
  spec.metadata['changelog_uri'] = "#{source_uri}/releases"
  spec.metadata['bug_tracker_uri'] = "#{source_uri}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('lib/**/*') + ['README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'schematist', '~> 1.0'

  spec.post_install_message = <<~MESSAGE
    ruby_llm-schema is now schematist. This release only forwards to it.
    Switch your Gemfile to `gem 'schematist'` and RubyLLM::Schema to Schematist::Schema.
  MESSAGE
end
