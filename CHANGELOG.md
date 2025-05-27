# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [1.0.1]

This release does not include changes to the Terraform module itself.

### Added

- Migration guide for upgrading to v1

### Fixed

- Fixed a release pipeline issue where tags were not being created

## [1.0.0]

This change introduces a number of breaking changes and new functionality. Most notably, the configuration of Fides is now done through terraform variables, rather than through arbitrary environment variables. Additionally, the module now supports Fides workers and adds a Cloudfront distribution for caching resources.

If you are upgrading from a previous version of this module, be sure to review your `terraform plan` output for any forced replacements and monitor your deployment logs for any issues.

### Added

- **Breaking:** First-class terraform variables to control more of Fides' configuration
- Support for private Docker image access
- Cloudfront for Fides and the Privacy Center
- Access logging and additional buckets, including a DSR bucket
- Queue specific workers

### Changed

- Added some defaults to input variables
- Split out environment variables to be shared between worker & webserver
- Improved variable validation
- Improved security group configuration
- Removed reference to `fidesops`
- Fix deprecated EIP attribute

## [0.0.2] - 2025-03-26

### Changed

- Updated command for launching privacy center through ECS

## [0.0.1] - 2023-01-06

Initial release
