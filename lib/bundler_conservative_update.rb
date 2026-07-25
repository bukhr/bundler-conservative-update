# frozen_string_literal: true

require_relative "bundler_conservative_update/version"

module BundlerConservativeUpdate
  # Explicit update strategies. When the user passes one of these, they have
  # already chosen how far the update may reach, so nothing is injected.
  LEVEL_FLAGS = %w[--patch --minor --major].freeze

  # Marker set on the re-executed process so the hook does not loop forever.
  APPLIED_ENV = "BUNDLER_CONSERVATIVE_UPDATE_APPLIED"

  # Escape hatch: set to "1" or "true" to run a genuinely unrestricted
  # `bundle update` when transitive updates are intended.
  DISABLE_ENV = "BUNDLER_CONSERVATIVE_UPDATE_DISABLE"

  # Decides whether a `bundle update` invocation should be re-executed with
  # --conservative. Instantiated with injected dependencies (argv, env and
  # Bundler's unlock state) to keep it testable without a real Bundler run.
  class Hook
    def initialize(argv:, env:, unlock:)
      @argv   = argv
      @env    = env
      @unlock = unlock
    end

    # True when the current command is a plain `bundle update` that has not
    # already opted into --conservative or an explicit update strategy.
    def should_inject?
      return false unless @argv.first == "update"
      return false if @unlock.is_a?(Hash) && @unlock[:conservative]
      return false if @argv.any? { |arg| LEVEL_FLAGS.include?(arg) }
      return false if @env[APPLIED_ENV] == "1"
      return false if disabled?

      true
    end

    # The original argv with --conservative inserted right after "update".
    def conservative_argv
      new_argv = @argv.dup
      pos = new_argv.index("update") || 0
      new_argv.insert(pos + 1, "--conservative")
      new_argv
    end

    private

    def disabled?
      %w[1 true].include?(@env[DISABLE_ENV].to_s.downcase)
    end
  end
end
