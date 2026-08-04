# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 1.0.0 - 2026-08-05

### Added

- Initial release: `bundle update` invocations that name gems, or a group, are
  re-executed with `--conservative`, so only those gems are unlocked and
  transitive dependencies stay locked.
- Invocations that name nothing to update are left to Bundler, since
  `--conservative` without an explicit unlock widens the resolution to every
  direct dependency: a bare `bundle update`, `--all`, `--bundler`, `--source`
  and `--ruby`.
- Explicit update strategies are respected: `--conservative`, `--patch`,
  `--minor`, `--major` and `--strict` all suppress the injection.
- Values of `--gemfile`, `--jobs`/`-j`, `--cooldown` and `--retry`/`-r` are not
  mistaken for gem names.
- `BUNDLER_CONSERVATIVE_UPDATE_DISABLE=1` (or `true`) opts a single run out.
