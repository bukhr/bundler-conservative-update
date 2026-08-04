# bundler-conservative-update

[![CI](https://github.com/bukhr/bundler-conservative-update/actions/workflows/ci.yml/badge.svg)](https://github.com/bukhr/bundler-conservative-update/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/bundler-conservative-update)](https://rubygems.org/gems/bundler-conservative-update)

A [Bundler plugin](https://bundler.io/guides/bundler_plugins.html) that makes
[`bundle update`](https://bundler.io/man/bundle-update.1.html) conservative by
default: only the gems you name get updated, and transitive dependencies stay
locked.

```console
$ bundle update rails                 # behaves like `bundle update --conservative rails`
$ bundle update --all                 # untouched: explicit "update everything"
$ bundle update --minor rails         # untouched: explicit strategy
```

## The problem

`bundle update rails` does not just update `rails`. Bundler also unlocks its
dependencies and moves them to the newest versions the `Gemfile` allows, so a
one-gem bump produces a `Gemfile.lock` diff nobody asked for or reviewed:

```console
bundle update rails && git diff --stat Gemfile.lock
 Gemfile.lock | 74 +++++++++++++++++++++++-----------------------
```

[`--conservative`](https://bundler.io/man/bundle-update.1.html) avoids this, but
it is opt-in per invocation: it only helps when every person and every script
remembers to type it, and Bundler has no setting to make it the default
(`prefer_patch` is related but different, see
[Relationship to prefer_patch](#relationship-to-prefer_patch)).

This plugin turns that behavior into the project's default. Because it is
declared in the `Gemfile`, the policy covers every `bundle update` run on the
project — yours, your teammates', and CI's — with no flag to remember.

## Installation

Add the plugin to your `Gemfile`:

```ruby
plugin "bundler-conservative-update"
```

The next `bundle install` installs the plugin.

See [bundle-plugin](https://bundler.io/man/bundle-plugin.1.html).

## Usage

There is nothing to configure. Run `bundle update` as usual:

```console
bundle update rails
bundler-conservative-update: re-running with --conservative (only requested gems are updated; set BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 to opt out)
  Pass --patch, --minor, --major or --all to choose a different update strategy.
```

The plugin re-executes the command as `bundle update --conservative rails`. It
injects only when the invocation **names something to update** and has not
already stated its own update strategy:

| Invocation | `--conservative` injected? | Why |
|---|---|---|
| `bundle update rails` | yes | names a gem |
| `bundle update rails --local` | yes | flags that do not change resolution scope are preserved |
| `bundle update --group dev` | yes | Bundler expands the group into the gems to unlock |
| `bundle update` (no gems) | no | names nothing; see note below |
| `bundle install`, `bundle exec`, `bundle lock`, … | no | not an update |
| `bundle update --conservative rails` | no | already requested; also the recursion guard |
| `bundle update --patch/--minor/--major/--strict rails` | no | explicit update strategy |
| `bundle update --all` | no | explicit "update everything" |
| `bundle update --bundler[=X]`, `--source[=X]`, `--ruby` | no | see note below |
| any of the above with `BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1` | no | [opt-out](#opting-out) |

> All the "names nothing" cases share one reason. `--conservative` restricts the
> resolution through the list of gems Bundler was explicitly asked to unlock;
> when that list is empty, Bundler falls back to unlocking **every** direct
> dependency of the `Gemfile` — the exact outcome this plugin exists to prevent.
> A bare `bundle update` names no gem, and `--bundler`, `--source` and `--ruby`
> change *what* is being resolved rather than naming gems, so injecting there
> would not restrict anything. Those invocations are left to Bundler.

The re-execution uses `Kernel.exec`, which replaces the current process: stdin
and the TTY are inherited, and the exit code you get is the real
`bundle update`'s.

### Opting out

To let a single update reach transitive dependencies on purpose, set
`BUNDLER_CONSERVATIVE_UPDATE_DISABLE` to `1` or `true` (case-insensitive):

```console
BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 bundle update rails
```

There is no permanent, per-project opt-out by design: a project that wants
unconstrained updates should not declare the plugin. For the periodic "update
everything" chore no variable is needed — `--all` is already respected:

```console
bundle update --all
```

## Relationship to `prefer_patch`

Bundler's [`prefer_patch`](https://bundler.io/man/bundle-config.1.html) setting
(`BUNDLE_PREFER_PATCH`) makes `bundle update` behave like
`bundle update --patch`. That controls the **level** of the updates (prefer
patch releases over minor/major), not their **scope**: shared and transitive
dependencies can still move.

`--conservative` controls the scope: only the gems you named are unlocked,
everything else stays exactly as locked. This plugin automates the scope part
only.

The two compose. The hook inspects `ARGV`, not Bundler's configuration, so
`BUNDLE_PREFER_PATCH` does not suppress the injection: with both in place,
`bundle update rails` updates only `rails` and prefers a patch release. Passing
`--patch` explicitly on the command line does suppress it, because then the
invocation already states its own strategy.

## Limitations

- **`bundle update` with no gems named is not protected.** The plugin steps
  aside there, so the run behaves like a plain full update. Name the gems you
  want, or pass `--all` to be explicit about it.
- **`bundle lock --update` is not covered.** It resolves through a code path
  that never fires plugin hooks, so the plugin cannot see the invocation, let
  alone re-execute it. Prefer `bundle update`, and review the `Gemfile.lock`
  diff by hand when you do reach for
  [`bundle lock --update`](https://bundler.io/man/bundle-lock.1.html).
- **`--bundler`, `--source` and `--ruby` are left unprotected**, for the reason
  described in [Usage](#usage).
- **Tools that resolve the lockfile without running `bundle update` locally**
  (Dependabot, Renovate, and similar) are not covered.
- **A fresh clone is unprotected until `bundle install` has run**, since that is
  what installs the plugin.

## How it works

[`plugins.rb`](plugins.rb) registers a `before-install-all` hook, which also
runs for `bundle update`. On that hook,
[`BundlerConservativeUpdate::Hook`](lib/bundler_conservative_update.rb) inspects
`ARGV`: it locates the subcommand (the first argument that is not an option,
skipping the value of options like `--retry 3`), checks that the invocation
names a gem or a group and carries no explicit strategy, and then re-executes
`bundle` with `--conservative` inserted right after the subcommand.

The decision tables live in
[`lib/bundler_conservative_update.rb`](lib/bundler_conservative_update.rb) —
`SKIP_FLAGS`, `SKIP_FLAG_PREFIXES`, `VALUE_FLAGS` and `UPDATE_VALUE_FLAGS`. That
is the one place to touch when a flag needs to be added.

No environment marker is involved. Recursion stops on its own because the
re-executed command carries `--conservative` in its own `ARGV`, and that flag is
one of the reasons the hook declines to inject.

## Development

```console
bundle install
bundle exec rake test
```

The suite includes an integration test that installs the plugin into a
throwaway project and runs a real `bundle update` against it. To run only the
unit tests, or a single file:

```console
SKIP_INTEGRATION=1 bundle exec rake test
bundle exec ruby -Itest test/hook_test.rb
```

[CI](.github/workflows/ci.yml) runs the full suite on Ruby 3.0 through 3.4.

## Contributing

Bug reports and pull requests are welcome at
[github.com/bukhr/bundler-conservative-update](https://github.com/bukhr/bundler-conservative-update/issues).
Please include the Bundler version and the exact `bundle update` invocation in
bug reports, and make sure `bundle exec rake test` passes on pull requests.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

The gem is available as open source under the terms of the
[MIT License](LICENSE.txt).
