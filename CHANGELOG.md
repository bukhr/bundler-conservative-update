# Changelog

## Unreleased

## 0.1.0

- Initial release: plain `bundle update` invocations are re-executed with
  `--conservative`, keeping transitive dependencies locked.
- Explicit `--patch`, `--minor` and `--major` invocations are left untouched.
