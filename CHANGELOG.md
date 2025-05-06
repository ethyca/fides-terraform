# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- First-class terraform variables to control more of Fides' configuration
- Support for private Docker image access
- Cloudfront for Fides and the Privacy Center
- Access logging and additional buckets, including a DSR bucket
- Queue specific workers

### Changed

- Added some defaults to input variables
- Split out environment variables to be shared between worker & webserver
- Improved variable validation
- Improved security group configuration
- Removed reference to fidesops
- Deprecated EIP attribute

### Added

### Fixed

## [0.0.2] - 2025-03-26

### Changed

- Updated command for launching privacy center through ECS

## [0.0.1] - 2023-01-06

Initial release
