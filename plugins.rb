# frozen_string_literal: true

# Bundler plugin entrypoint. When a plain `bundle update` is detected, the
# process is re-executed with --conservative so only the requested gems are
# updated and transitive dependencies stay locked.

require "bundler_conservative_update"

Bundler::Plugin.add_hook("before-install-all") do |_dependencies|
  unlock = Bundler.definition.instance_variable_get(:@unlock)
  hook   = BundlerConservativeUpdate::Hook.new(argv: ARGV, env: ENV, unlock: unlock)

  next unless hook.should_inject?

  Bundler.ui.info("bundler-conservative-update: applying --conservative (only the requested gems are updated; transitive dependencies stay locked)")
  Bundler.ui.info("  Pass --patch, --minor or --major to choose a different update strategy, or set")
  Bundler.ui.info("  BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 to run an unrestricted update on purpose.")

  ENV[BundlerConservativeUpdate::APPLIED_ENV] = "1"
  bundle_bin = Gem.loaded_specs["bundler"].bin_file("bundle")
  Kernel.exec(Gem.ruby, bundle_bin, *hook.conservative_argv)
end
