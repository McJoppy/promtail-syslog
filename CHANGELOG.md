# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

## [0.3.0] - 2024-11-15

### Added

- install `promtail` for based off arch (`arm64`/`amd64`)
- `promtail` runs as non `root` user
- additional duplicate label for `hostname` (`host` kept for compatibility)
- additional label for `severity`
- additional label for `facility`
- additional lavel for `appname`

### Changed

- latest version of `promtail` will be installed
- `supervisord.conf` updated to surpress warning regarding running as `root`

### Deprecated

- `host` label will be removed in the future

## [0.2.0] - 2023-07-16

### Added

- `rsyslog-mmutf8fix` module
- `rsyslog-mmjsonparse` module

## [0.1.0] - 2023-06-18

Initial release of container to Docker hub