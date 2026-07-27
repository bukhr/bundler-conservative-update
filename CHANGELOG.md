# Changelog

## Unreleased

- `--strict`, `--all`, `--bundler`, `--source` and `--ruby` now suppress the
  injection, alongside `--conservative`, `--patch`, `--minor` and `--major`.
  `--all` is an explicit request to update everything, and the other three
  would make Bundler unlock every direct dependency once `--conservative` was
  added.
- The subcommand is now located as the first non-option argument instead of
  assuming it comes first, so global options preceding it no longer defeat the
  detection.
- Dropped the `BUNDLER_CONSERVATIVE_UPDATE_APPLIED` marker and the
  introspection of Bundler's internal unlock state. Recursion stops because the
  re-executed command already carries `--conservative`.
- The plugin now announces itself through `Bundler.ui.warn`, so the message
  survives `--quiet`, and steps aside instead of crashing when the bundler gem
  spec cannot be located.
- Documented that `bundle lock --update` is out of reach: it resolves without
  firing plugin hooks.

## 0.1.0

- Initial release: plain `bundle update` invocations are re-executed with
  `--conservative`, keeping transitive dependencies locked.
- Explicit `--patch`, `--minor` and `--major` invocations are left untouched.
