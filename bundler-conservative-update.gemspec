# frozen_string_literal: true

require_relative "lib/bundler_conservative_update/version"

Gem::Specification.new do |spec|
  spec.name    = "bundler-conservative-update"
  spec.version = BundlerConservativeUpdate::VERSION
  spec.summary = "A Bundler plugin that makes `bundle update` conservative by default"
  spec.description = "Re-executes every plain `bundle update` with --conservative, so only the gems " \
                     "you name are updated and transitive dependencies stay locked. Explicit " \
                     "strategies (--patch, --minor, --major) and an opt-out are respected."
  spec.authors = ["Buk"]
  spec.email   = ["contacto@buk.cl"]
  spec.license = "MIT"
  spec.homepage = "https://github.com/bukhr/bundler-conservative-update"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "plugins.rb", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"
end
