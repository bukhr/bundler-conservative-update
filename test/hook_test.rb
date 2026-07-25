# frozen_string_literal: true

require_relative "test_helper"

class HookTest < Minitest::Test
  Hook = BundlerConservativeUpdate::Hook

  def test_injects_on_update_with_a_gem
    hook = Hook.new(argv: ["update", "rails"], env: {}, unlock: { gems: ["rails"] })

    assert_predicate hook, :should_inject?
  end

  def test_injects_on_update_all
    hook = Hook.new(argv: ["update", "--all"], env: {}, unlock: { gems: [] })

    assert_predicate hook, :should_inject?
  end

  def test_injects_on_bare_update
    hook = Hook.new(argv: ["update"], env: {}, unlock: true)

    assert_predicate hook, :should_inject?
  end

  def test_does_not_inject_on_install
    hook = Hook.new(argv: ["install"], env: {}, unlock: { gems: [] })

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_on_exec
    hook = Hook.new(argv: ["exec", "rails", "s"], env: {}, unlock: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_when_unlock_is_already_conservative
    hook = Hook.new(
      argv:   ["update", "rails"],
      env:    {},
      unlock: { gems: ["rails"], conservative: true },
    )

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_patch_flag
    hook = Hook.new(argv: ["update", "--patch", "rails"], env: {}, unlock: { gems: ["rails"] })

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_minor_flag
    hook = Hook.new(argv: ["update", "--minor", "rails"], env: {}, unlock: { gems: ["rails"] })

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_major_flag
    hook = Hook.new(argv: ["update", "--major", "rails"], env: {}, unlock: { gems: ["rails"] })

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_when_already_applied
    hook = Hook.new(
      argv:   ["update", "rails"],
      env:    { BundlerConservativeUpdate::APPLIED_ENV => "1" },
      unlock: { gems: ["rails"] },
    )

    refute_predicate hook, :should_inject?
  end

  def test_conservative_argv_inserts_after_update
    hook = Hook.new(argv: ["update", "rails"], env: {}, unlock: {})

    assert_equal ["update", "--conservative", "rails"], hook.conservative_argv
  end

  def test_conservative_argv_preserves_multiple_gems
    hook = Hook.new(argv: ["update", "rails", "puma", "sidekiq"], env: {}, unlock: {})

    assert_equal ["update", "--conservative", "rails", "puma", "sidekiq"], hook.conservative_argv
  end

  def test_conservative_argv_preserves_existing_flags
    hook = Hook.new(argv: ["update", "--quiet", "rails"], env: {}, unlock: {})

    assert_equal ["update", "--conservative", "--quiet", "rails"], hook.conservative_argv
  end

  def test_conservative_argv_does_not_mutate_original_argv
    argv = ["update", "rails"]
    hook = Hook.new(argv: argv, env: {}, unlock: {})
    hook.conservative_argv

    assert_equal ["update", "rails"], argv
  end
end
