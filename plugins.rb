# frozen_string_literal: true

# Bundler plugin entrypoint. When a `bundle update` without an explicit update
# strategy is detected, the process is re-executed with --conservative so only
# the requested gems are updated and transitive dependencies stay locked.

require "bundler_conservative_update"

Bundler::Plugin.add_hook("before-install-all") do |_dependencies|
  hook = BundlerConservativeUpdate::Hook.new(argv: ARGV, env: ENV)

  next unless hook.should_inject?

  spec = Gem.loaded_specs["bundler"]

  # Without a loaded bundler spec there is no reliable path to re-execute, so
  # the plugin steps aside and lets the plain update run.
  next if spec.nil?

  # CLI::Update raises the ui level to warn before this hook runs, so info
  # messages are invisible under --quiet. The headline goes through warn.
  Bundler.ui.warn("bundler-conservative-update: re-running with --conservative (only requested gems are updated; set BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 to opt out)")
  Bundler.ui.info("  Pass --patch, --minor, --major or --all to choose a different update strategy.")

  Kernel.exec(Gem.ruby, spec.bin_file("bundle"), *hook.conservative_argv)
end
