# frozen_string_literal: true

require_relative "test_helper"

class HookTest < Minitest::Test
  Hook = BundlerConservativeUpdate::Hook

  def test_injects_on_update_with_a_gem
    hook = Hook.new(argv: ["update", "rails"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_injects_on_bare_update
    hook = Hook.new(argv: ["update"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_injects_on_update_with_several_gems
    hook = Hook.new(argv: ["update", "rails", "puma", "sidekiq"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_injects_with_a_leading_global_flag
    hook = Hook.new(argv: ["--verbose", "update", "rails"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_injects_with_a_leading_global_flag_that_takes_a_value
    hook = Hook.new(argv: ["--retry", "3", "update", "rails"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_injects_with_a_leading_short_global_flag_that_takes_a_value
    hook = Hook.new(argv: ["-r", "3", "update", "rails"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_injects_with_the_local_flag
    hook = Hook.new(argv: ["update", "--local", "rails"], env: {})

    assert_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_conservative_flag
    hook = Hook.new(argv: ["update", "--conservative", "rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_patch_flag
    hook = Hook.new(argv: ["update", "--patch", "rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_minor_flag
    hook = Hook.new(argv: ["update", "--minor", "rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_major_flag
    hook = Hook.new(argv: ["update", "--major", "rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_strict_flag
    hook = Hook.new(argv: ["update", "--strict", "--minor", "rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_all_flag
    hook = Hook.new(argv: ["update", "--all"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_bundler_flag
    hook = Hook.new(argv: ["update", "--bundler"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_bundler_flag_carrying_a_value
    hook = Hook.new(argv: ["update", "--bundler=2.5.0"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_source_flag
    hook = Hook.new(argv: ["update", "--source", "rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_source_flag_carrying_a_value
    hook = Hook.new(argv: ["update", "--source=rails"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_with_ruby_flag
    hook = Hook.new(argv: ["update", "--ruby"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_on_install
    hook = Hook.new(argv: ["install"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_on_exec
    hook = Hook.new(argv: ["exec", "rails", "s"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_on_lock
    hook = Hook.new(argv: ["lock", "--update"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_without_a_subcommand
    hook = Hook.new(argv: ["--version"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_when_update_is_the_value_of_a_global_flag
    hook = Hook.new(argv: ["--retry", "update", "install"], env: {})

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_when_disabled_with_1
    hook = Hook.new(argv: ["update", "rails"], env: { BundlerConservativeUpdate::DISABLE_ENV => "1" })

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_when_disabled_with_true
    hook = Hook.new(argv: ["update", "rails"], env: { BundlerConservativeUpdate::DISABLE_ENV => "true" })

    refute_predicate hook, :should_inject?
  end

  def test_does_not_inject_when_disabled_with_uppercase_true
    hook = Hook.new(argv: ["update", "rails"], env: { BundlerConservativeUpdate::DISABLE_ENV => "TRUE" })

    refute_predicate hook, :should_inject?
  end

  def test_injects_when_disable_is_set_to_a_falsy_value
    hook = Hook.new(argv: ["update", "rails"], env: { BundlerConservativeUpdate::DISABLE_ENV => "0" })

    assert_predicate hook, :should_inject?
  end

  def test_conservative_argv_inserts_after_update
    hook = Hook.new(argv: ["update", "rails"], env: {})

    assert_equal ["update", "--conservative", "rails"], hook.conservative_argv
  end

  def test_conservative_argv_preserves_multiple_gems
    hook = Hook.new(argv: ["update", "rails", "puma", "sidekiq"], env: {})

    assert_equal ["update", "--conservative", "rails", "puma", "sidekiq"], hook.conservative_argv
  end

  def test_conservative_argv_preserves_existing_flags
    hook = Hook.new(argv: ["update", "--quiet", "rails"], env: {})

    assert_equal ["update", "--conservative", "--quiet", "rails"], hook.conservative_argv
  end

  def test_conservative_argv_inserts_after_a_leading_global_flag
    hook = Hook.new(argv: ["--verbose", "update", "rails"], env: {})

    assert_equal ["--verbose", "update", "--conservative", "rails"], hook.conservative_argv
  end

  def test_conservative_argv_inserts_after_a_global_flag_carrying_a_value
    hook = Hook.new(argv: ["--retry", "3", "update", "rails"], env: {})

    assert_equal ["--retry", "3", "update", "--conservative", "rails"], hook.conservative_argv
  end

  def test_conservative_argv_does_not_mutate_original_argv
    argv = ["update", "rails"]
    hook = Hook.new(argv: argv, env: {})
    hook.conservative_argv

    assert_equal ["update", "rails"], argv
  end
end
