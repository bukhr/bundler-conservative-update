# frozen_string_literal: true

require_relative "test_helper"

require "open3"
require "tmpdir"

# Drives a real `bundle` against a throwaway Gemfile that loads the plugin from
# this checkout. Set SKIP_INTEGRATION=1 to run only the unit tests.
class IntegrationTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  PLUGIN_LINE = "bundler-conservative-update: re-running with --conservative"

  def setup
    skip("SKIP_INTEGRATION is set") if ENV["SKIP_INTEGRATION"]
    skip("bundle is not available") unless bundle_available?
  end

  def test_bare_update_is_re_executed_once_with_conservative
    in_bundle_project do |gemfile|
      output = bundle(gemfile, "update")

      assert_equal 1, output.scan(PLUGIN_LINE).length, output
    end
  end

  def test_update_all_is_left_alone
    in_bundle_project do |gemfile|
      output = bundle(gemfile, "update", "--all")

      refute_includes output, PLUGIN_LINE, output
    end
  end

  def test_update_is_left_alone_when_disabled
    in_bundle_project do |gemfile|
      output = bundle(gemfile, "update", "BUNDLER_CONSERVATIVE_UPDATE_DISABLE" => "1")

      refute_includes output, PLUGIN_LINE, output
    end
  end

  private

  def in_bundle_project
    Dir.mktmpdir("bundler-conservative-update") do |dir|
      gemfile = File.join(dir, "Gemfile")
      File.write(gemfile, <<~GEMFILE)
        source "https://rubygems.org"

        plugin "bundler-conservative-update", path: #{REPO_ROOT.inspect}
      GEMFILE

      output = bundle(gemfile, "install")
      skip("bundle install failed: #{output}") unless output.include?("Installed plugin bundler-conservative-update")

      yield(gemfile)
    end
  end

  def bundle(gemfile, *args, **overrides)
    env = clean_env(gemfile).merge(overrides)
    output, = Open3.capture2e(env, "bundle", *args, chdir: File.dirname(gemfile))
    output
  end

  # A child bundle must not inherit the outer bundle's configuration, and the
  # plugin has to be installed inside the throwaway project.
  def clean_env(gemfile)
    env = ENV.keys.grep(/\ABUNDLE_/).to_h { |key| [key, nil] }
    env.merge(
      "BUNDLE_GEMFILE" => gemfile,
      "BUNDLE_USER_HOME" => File.join(File.dirname(gemfile), ".bundle"),
      "RUBYOPT" => nil,
      BundlerConservativeUpdate::DISABLE_ENV => nil,
    )
  end

  def bundle_available?
    Open3.capture2e("bundle", "--version")
    true
  rescue Errno::ENOENT
    false
  end
end
