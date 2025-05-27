# Changelog

All notable changes to this project will be documented in this file.

[![Common Changelog](https://common-changelog.org/badge.svg)](https://common-changelog.org)

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [1.0.2] - 2025-05-27

This release does not include changes to the Terraform module itself.

### Added

- Added `.terraform-version` file to ensure consistent Terraform version between CI/CD pipeline and local development.

### Changed

- Updated CI/CD pipeline to use latest dependencies
- Update CHANGELOG to use Common Changelog format

### Fixed

- Release pipeline issue after tag creation

## [1.0.1] - 2025-05-27

This release does not include changes to the Terraform module itself.

### Added

- Migration guide for upgrading to v1

### Fixed

- Fixed a release pipeline issue where tags were not being created

## [1.0.0] - 2025-05-22

This change introduces a number of breaking changes and new functionality. Most notably, the configuration of Fides is now done through terraform variables, rather than through arbitrary environment variables. Additionally, the module now supports Fides workers and adds a Cloudfront distribution for caching resources.

_If you are upgrading: please see [`UPGRADE_TO_v1.md`](UPGRADE_TO_v1.md)._

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
