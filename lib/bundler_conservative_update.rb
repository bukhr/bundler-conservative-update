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

  # Options of `bundle update` that take a separate value argument. That value
  # must not be mistaken for a gem name, as in the `4` of `--jobs 4`.
  UPDATE_VALUE_FLAGS = %w[--gemfile --jobs -j --cooldown --retry -r].freeze

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

    # True when the current command is a `bundle update` that names a scope to
    # update and has not already stated its own update strategy.
    def should_inject?
      index = update_index

      return false if index.nil?
      return false unless @argv[index] == "update"

      args = @argv[(index + 1)..] || []

      return false if skip_flag?(args)
      return false unless scope?(args)
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

    # True when the invocation names something to update: gems, or a group
    # whose direct dependencies Bundler expands into the gem list.
    #
    # A bare `bundle update` names nothing. Bundler treats that as a full
    # update and, with a --conservative that carries no explicit unlocks,
    # falls back to unlocking every direct dependency of the Gemfile. The
    # injection would neither restrict the resolution nor match the message the
    # plugin prints, so the invocation is left alone, same as --all.
    def scope?(args)
      gem_names?(args) || group_flag?(args)
    end

    def gem_names?(args)
      index = 0

      while index < args.length
        arg = args[index]

        if UPDATE_VALUE_FLAGS.include?(arg)
          index += 2
          next
        end

        return true unless arg.start_with?("-")

        index += 1
      end

      false
    end

    # --group is matched by prefix so `--group foo` and `--group=foo` are both
    # covered, plus the -g alias.
    def group_flag?(args)
      args.any? { |arg| arg == "-g" || arg.start_with?("--group") }
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
