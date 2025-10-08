lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/rustore_connect/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-rustore_connect'
  spec.version       = Fastlane::RustoreConnect::VERSION
  spec.author        = 'Mikhail Matsera'
  spec.email         = 'mmatsera@gmail.com'

  spec.summary       = 'Fastlane plugin for publishing Android applications to RuStore.'
  spec.homepage      = "https://github.com/jetcore/fastlane-plugin-rustore_connect"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.6'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
end
