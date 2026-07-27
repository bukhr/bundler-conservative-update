# bundler-conservative-update

A [Bundler plugin](https://bundler.io/guides/bundler_plugins.html) that makes
`bundle update` conservative by default: only the gems you name get updated,
and transitive dependencies stay locked.

## The problem

By default, `bundle update rails` does not just update `rails`. Bundler also
unlocks its dependencies and updates them to the newest versions your Gemfile
allows. You asked to bump one gem and your `Gemfile.lock` diff now touches
dozens of gems nobody asked for or reviewed. In a large application this is a
classic source of breakage that is hard to trace back ("I only updated rails,
why did PDF generation break?").

Bundler ships a flag that avoids this, `bundle update --conservative rails`,
which updates only the named gems and leaves shared dependencies alone. But it
is opt-in per invocation: it only helps when every person (and script) on the
project remembers to type it. There is no Bundler configuration to make it the
default (`prefer_patch` is related but different, see
[below](#how-is-this-different-from-prefer_patch)).

This plugin turns the safe behavior into the project's default. Because it is
declared in the Gemfile, the policy covers every `bundle update` run on the
project, by anyone and by CI, without each invocation having to remember the
flag. It does not cover `bundle lock --update`, see
[Limitations](#limitations).

## Installation

Add the plugin to your `Gemfile`:

```ruby
plugin "bundler-conservative-update"
```

The next `bundle install` installs the plugin. Alternatively, install it
directly:

```console
$ bundle plugin install bundler-conservative-update
```

## Usage

There is nothing to configure. Run `bundle update` as usual:

```console
$ bundle update rails
bundler-conservative-update: re-running with --conservative (only requested gems are updated; set BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 to opt out)
```

The plugin detects the `bundle update` invocation and re-executes it as
`bundle update --conservative rails`.

The plugin stays out of the way when the command already states its own update
strategy or scope. Nothing is injected when:

- the command is not `bundle update` (install, exec, lock, etc.);
- you already passed `--conservative` yourself;
- you passed an explicit update strategy: `--patch`, `--minor`, `--major` or
  `--strict`;
- you passed `--all`, which is an explicit request to update everything;
- you passed `--bundler` (in any form, including `--bundler=2.5.0`),
  `--source` (including `--source=rails`) or `--ruby`. These change what is
  being resolved rather than naming gems to update: with an injected
  `--conservative` and no explicitly unlocked gem, Bundler's conservative
  branch falls back to unlocking **every** direct dependency, which is the
  outcome this plugin exists to prevent;
- the opt-out environment variable is set (see below).

Flags that do not change the scope of the resolution, such as `--local` or
`--quiet`, are preserved and do not disable the injection.

### Opting out

To let a single update reach transitive dependencies on purpose, set:

```console
$ BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 bundle update rails
```

For the periodic "update everything" chore, no environment variable is needed:
`--all` is respected as an explicit request.

```console
$ bundle update --all
```

Explicit strategies are always respected too:

```console
$ bundle update --minor rails
```

## How is this different from `prefer_patch`?

Bundler's `prefer_patch` setting (`BUNDLE_PREFER_PATCH`) makes `bundle update`
behave like `bundle update --patch`. That controls the **level** of the
updates (prefer patch releases over minor/major), but it does not control
their **scope**: shared and transitive dependencies can still be updated.

`--conservative` controls the scope: only the gems you named are unlocked;
everything else stays exactly as locked. The two are complementary, and this
plugin only automates the scope part.

## Limitations

`bundle lock --update` is not covered. It resolves through a code path that
never fires plugin hooks, so the plugin cannot see the invocation, let alone
re-execute it. Prefer `bundle update` when you want the conservative default,
and review the `Gemfile.lock` diff by hand when you do reach for
`bundle lock --update`.

## How it works

Bundler plugins can hook into `before-install-all`, which also runs for
`bundle update`. On that hook the plugin inspects `ARGV`: it locates the
subcommand (the first argument that is not an option) and, when the command
qualifies, re-executes `bundle` with `--conservative` inserted right after it.

No environment marker is involved. Recursion stops on its own because the
re-executed command carries `--conservative` in its own `ARGV`, and that flag
is one of the reasons the plugin declines to inject.

## Development

```console
$ bundle install
$ bundle exec rake test
```

The suite includes an integration test that installs the plugin into a
throwaway project and runs a real `bundle update` against it. Set
`SKIP_INTEGRATION=1` to run only the unit tests.

## License

The gem is available as open source under the terms of the
[MIT License](LICENSE.txt).
