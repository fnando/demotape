# Changelog

<!--
Prefix your message with one of the following:

- [Added] for new features.
- [Changed] for changes in existing functionality.
- [Deprecated] for soon-to-be removed features.
- [Removed] for now removed features.
- [Fixed] for any bug fixes.
- [Security] in case of vulnerabilities.
-->

## Unreleased

- [Changed] Re-implemented parser.
- [Added] Add `Group` command to group multiple commands together.
- [Added] Add `Run` command to execute shell commands (combines Type, Sleep,
  Enter, Sleep).
- [Added] Add `Set run_enter_delay` configuration option (default: 300ms).
- [Added] Add `Set run_sleep` configuration option (default: 1s).

## v0.0.2

- [Added] Add `demotape completion` command to generate shell completions.

## v0.0.1

- [Added] Command `demotape ascii` to print ASCII logo.
- [Added] Support for exporting `.avi` (lossless)
- [Changed] Export lossless videos now by default
- [Fixed] Export screenshots only once per path

## v0.0.0

- Initial release.
