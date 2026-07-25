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
declared in the Gemfile, the policy applies to everyone who works on the
project, including CI, with no individual discipline required.

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
bundler-conservative-update: applying --conservative (only the requested gems are updated; transitive dependencies stay locked)
```

The plugin detects the plain `bundle update` invocation and re-executes it as
`bundle update --conservative rails`.

The plugin stays out of the way when you have already chosen an update
strategy. Nothing is injected when:

- the command is not `bundle update` (install, exec, etc.);
- you already passed `--conservative` yourself;
- you passed an explicit update level: `--patch`, `--minor` or `--major`;
- the opt-out environment variable is set (see below).

### Opting out

To run a genuinely unrestricted update on purpose (for example, a periodic
"update everything" chore), set:

```console
$ BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1 bundle update
```

Or choose an explicit level, which the plugin always respects:

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

## How it works

Bundler plugins can hook into `before-install-all`, which also runs for
`bundle update`. On that hook the plugin inspects `ARGV` and Bundler's unlock
state; when injection applies it re-executes the same command with
`--conservative` inserted, marking the child process with
`BUNDLER_CONSERVATIVE_UPDATE_APPLIED` so the hook does not recurse.

## Development

```console
$ bundle install
$ bundle exec rake test
```

## License

The gem is available as open source under the terms of the
[MIT License](LICENSE.txt).
