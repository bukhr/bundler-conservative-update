# frozen_string_literal: true

require_relative "bundler_conservative_update/version"

module BundlerConservativeUpdate
  # Flags that suppress the injection, matched exactly.
  #
  # --conservative is both the "the user already asked for it" case and the
  # recursion guard: the re-executed command carries the flag, so the hook
  # declines the second time around.
  #
  # --patch, --minor, --major and --strict are explicit update strategies, and
  # --all is an explicit "update everything" request. In all of them the user
  # has already stated how far the update may reach.
  #
  # --ruby changes what the resolution is about instead of naming gems to
  # update. Combined with an injected --conservative, Bundler's conservative
  # branch finds no explicit gem unlocks and falls back to unlocking every
  # direct dependency, which is the exact outcome this plugin prevents.
  SKIP_FLAGS = %w[--conservative --patch --minor --major --strict --all --ruby].freeze

  # Flags suppressed by prefix, so `--source foo` and `--source=foo` are both
  # covered. Same reasoning as --ruby: with an injected --conservative they
  # would unlock all direct dependencies.
  SKIP_FLAG_PREFIXES = %w[--bundler --source].freeze

  # Global options that take a separate value argument. That value must not be
  # mistaken for the subcommand, as in the `3` of `--retry 3`.
  VALUE_FLAGS = %w[--retry -r].freeze

  # Escape hatch: set to "1" or "true" to run a genuinely unrestricted
  # `bundle update` when transitive updates are intended.
  DISABLE_ENV = "BUNDLER_CONSERVATIVE_UPDATE_DISABLE"

  # Decides whether a `bundle update` invocation should be re-executed with
  # --conservative. Instantiated with injected argv and env so it can be tested
  # without a real Bundler run.
  class Hook
    def initialize(argv:, env:)
      @argv = argv
      @env  = env
    end

    # True when the current command is a `bundle update` that has not already
    # stated its own update strategy or scope.
    def should_inject?
      index = update_index

      return false if index.nil?
      return false unless @argv[index] == "update"
      return false if skip_flag?(@argv[(index + 1)..] || [])
      return false if disabled?

      true
    end

    # The original argv with --conservative inserted right after the
    # subcommand, leaving the receiver's argv untouched.
    def conservative_argv
      new_argv = @argv.dup
      new_argv.insert(update_index + 1, "--conservative")
      new_argv
    end

    private

    # Index of the subcommand: the first argument that is not an option,
    # skipping the value of the global options that take one.
    def update_index
      index = 0

      while index < @argv.length
        arg = @argv[index]

        if VALUE_FLAGS.include?(arg)
          index += 2
          next
        end

        return index unless arg.start_with?("-")

        index += 1
      end

      nil
    end

    def skip_flag?(args)
      args.any? do |arg|
        SKIP_FLAGS.include?(arg) || SKIP_FLAG_PREFIXES.any? { |prefix| arg.start_with?(prefix) }
      end
    end

    def disabled?
      %w[1 true].include?(@env[DISABLE_ENV].to_s.downcase)
    end
  end
end
