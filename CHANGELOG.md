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

- [Fixed] Handle `SIGINT` and `SIGQUIT` signals to gracefully stop recording.
- [Added] Add `--timeout` and `Set timeout duration` to specify a maximum time
  to wait for the demo tape execution.

## v0.0.8

- [Added] Add `WaitUntilDone`, which is just a shortcut for
  `WaitUntil /::done::/`.

## v0.0.7

- [Fixed] Fix key combos that had numbers in them not being recognized.

## v0.0.6

- [Added] Add `demotape run --working-dir` to specify the working directory for
  commands. Notice that this changes all path references to be relative to the
  working directory, including `--output-path` (if it's a relative path).
- [Fixed] Fix issue where `Set typing_speed` wasn't recognized.
- [Fixed] Fix issue where `Set shell` wasn't recognized.

## v0.0.5

- [Changed] Add newline to multiline strings if they don't end with one.
- [Fixed] Ensure multiline strings are passed as the argument.

## v0.0.4

- [Fixed] Fix how Thor handle defaults for arrays.
- [Fixed] Fix reading tapes from stdin.
- [Fixed] Fix `demotape help run` to expand to `_run`.

## v0.0.3

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
