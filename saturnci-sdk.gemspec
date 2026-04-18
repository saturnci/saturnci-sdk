# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'saturnci-sdk'
  spec.version = '0.1.0'
  spec.authors = ['Jason Swett']
  spec.summary = 'Ruby SDK for the SaturnCI API'
  spec.homepage = 'https://github.com/saturnci/saturnci-sdk'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'
  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
