# frozen_string_literal: true

require_relative "lib/bundler_conservative_update/version"

Gem::Specification.new do |spec|
  spec.name    = "bundler-conservative-update"
  spec.version = BundlerConservativeUpdate::VERSION
  spec.summary = "A Bundler plugin that makes `bundle update` conservative by default"
  spec.description = "Re-executes `bundle update` with --conservative, so only the gems you name " \
                     "are updated and transitive dependencies stay locked. Explicit strategies " \
                     "(--patch, --minor, --major, --strict), explicit scopes (--all, --source, " \
                     "--bundler, --ruby) and an opt-out are respected."
  spec.authors = ["Javier Omar Pacheco Moreno"]
  spec.email   = ["contacto@buk.cl"]
  spec.license = "MIT"
  spec.homepage = "https://github.com/bukhr/bundler-conservative-update"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "plugins.rb", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE.txt"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.0"
end
