# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-01
DOGOnews fork. Major version because the minimum supported Mongoid rose from 3.0 (1.1.4) to 7.0.

### Added
- `Mongoid::TaggableWithContext::AggregationStrategy::Aggregation`: tag counts rebuilt with the aggregation
  pipeline (`$unwind`/`$group`/`$out`) after each save that changes tags; loaded on Mongoid 5 and newer.
- Mongoid 8 and 9 support: the `MapReduce`, `RealTime`, `RealTimeGroupBy` and `Aggregation` save callbacks
  read `previous_changes` instead of `changes` on Mongoid 8+.
- GitHub Actions test matrix (`.github/workflows/test.yml`), seven rows from Ruby 2.7 / Rails 6.1 /
  Mongoid 7.5 / MongoDB 6.0 to Ruby 3.4 / Rails 8.0 / Mongoid 9.0 / MongoDB 8.0. The `Gemfile` selects
  Rails and Mongoid from `RAILS_VERSION` / `MONGOID_VERSION` (defaults 6.1 / 7.5).
- GitHub Release workflow (`.github/workflows/release.yml`): pushing a `vX.Y.Z` tag creates a GitHub Release
  with this file's section as the notes.
- Specs for `recalculate_tag_weights!`, `tags_autocomplete`, and aliased contexts under `RealTime` and
  `RealTimeGroupBy`.

### Changed
- Runtime dependency `mongoid >= 7.0, < 10` (was any version; 1.1.4 required `>= 3.0.0`).
- Specs run on RSpec 3.13 (keeping the `should` syntax, enabled explicitly) with `database_cleaner-mongoid`.
- jeweler replaced by `bundler/gem_tasks`; the gemspec no longer has a frozen `date`, and `homepage` points to
  this fork.
- README rewritten for the maintained fork (supported versions, every option and generated method, known
  issues); history moved to this file.

### Removed
- Travis CI configuration.

### Fixed
- `RealTime` / `RealTimeGroupBy` with an aliased context (`taggable :ints, as: :interests`): counts were written
  to the aggregation collection named after the database field but read from the one named after the context,
  so `Model.interests` was always empty; `RealTimeGroupBy` also looked up `group_by_field` under the database
  field name.
- `RealTime.recalculate_tag_weights!` (and therefore `recalculate_all_context_tag_weights!`) always raised
  `NoMethodError`.
- `RealTime.tags_autocomplete` raised `NoMethodError` when called without `:max`.

## [1.1.6] - 2018-06-01
### Changed
- `mongoid-compatibility` moved from the Gemfile to the gemspec as a runtime dependency; gemspec cleaned up
  (version read from `Mongoid::TaggableWithContext::VERSION`).

## [1.1.5] - 2018-06-01
### Added
- Mongoid 2, 4, 5 and 6 (Rails 5) support, using `mongoid-compatibility` (`alias_method_chain` removed).
- `:sort` in the conditions passed to `tags_for` / `tags_with_weight_for`.

### Fixed
- Conditions were ignored by `tags_for` and `tags_with_weight_for`.
- `RealTimeGroupBy` keeps its counts in a separate collection, so `:sort` and `:limit` also work when no group
  is given (previously the per-group counts were summed in memory).

## [1.1.4] - 2013-10-15
### Fixed
- `<context>_string` returns `""` instead of raising when the tags are `nil`.

## [1.1.3] - 2013-07-22
### Added
- `<context>_string=` setter.

### Fixed
- Setting tags to `nil` no longer raises an error.

## [1.1.2] - 2013-05-26
### Changed
- The separate `Mongoid::TaggableWithContext::GroupBy` module is merged into the main module; group-by counts
  are provided by the new `RealTimeGroupBy` aggregation strategy. Including the old `GroupBy` modules raises an
  error explaining the change. `tag_string_for` and friends use the singular "tag".

### Fixed
- Rails breakage in 1.1.1 and `Gem::InvalidSpecificationException` on `gem build`.

## [1.1.1] - 2013-05-19
### Added
- `#tags_string_for(context)`.

### Removed
- The `:string_method` option, instance-to-class delegation, and changing the separator after declaration.
  Setting tags to anything other than an Array or String raises `InvalidTagsFormat`.

## [1.1.0] - 2013-05-19
### Added
- `taggable <db_field>, as: <context>` (aliased Mongoid fields); all Mongoid `field` options pass through.

### Changed
- Version moved to `Mongoid::TaggableWithContext::VERSION`.

### Removed
- The `:field` option (use `as:`).

## [1.0.0] - 2013-02-16
Released to RubyGems by upstream. Not tagged here: the version file said 1.0.0 from 2013-01-16, but the
gemspec only reached 1.0.0 on 2013-02-16, and 0.8.2 was released from that range in between. 0.8.2 and 1.0.1
were also released to RubyGems by upstream but never appeared in this repository's version file.
### Added
- `tags=` accepts a String or an Array (`tags_array=` kept as an alias); `tags_string`.
- Mongoid 3 support; tags autocomplete; group-by aggregation (`group_by_field`).

### Changed
- Tags are stored in a field named after the context (`tags`), not `tags_array`.

## [0.8.1] - 2012-03-14
### Fixed
- Tags assigned through `tags_array=` are cleaned up (blanks removed).

## [0.8.0] - 2011-12-20
### Changed
- Aggregation strategies refactored; Mongoid dependency relaxed.

### Fixed
- Real-time aggregation; trailing separators; blank tags.

## [0.7.2] - 2011-08-04
No changes besides the version.

## [0.7.1] - 2011-08-04
### Removed
- Use of the deprecated `class_inheritable_reader`.

## [0.7.0] - 2011-08-04
### Changed
- Requires Mongoid 2.1 (`previous_changes` / `changes` behaviour).

## [0.6.2] - 2011-06-20
### Changed
- Depends on Mongoid 2.0.2.

## [0.6.1] - 2011-02-13
### Changed
- Documentation and development dependencies.

## [0.6.0] - 2011-02-12
### Changed
- Aggregation moved into separate strategy modules.

## [0.5.0] - 2011-02-12
### Added
- Specs, including `tagged_with`.

## [0.4.0] - 2011-02-11
### Changed
- `tag_contexts` delegated from instances to the class.

## [0.3.1] - 2011-02-11
### Fixed
- Spelling.

## [0.3.0] - 2011-02-11
### Changed
- Gem renamed to `mongoid_taggable_with_context`.

## [0.2.0] - 2011-02-11
### Fixed
- Errors in the initial release.

## [0.1.0] - 2011-02-11
### Added
- Initial release by Aaron Qian, based on [mongoid_taggable](https://github.com/ches/mongoid_taggable) by
  Wilker Lúcio and Ches Martin.

[Unreleased]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.6...v2.0.0
[1.1.6]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.8.1...v1.1.0
[0.8.1]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.7.2...v0.8.0
[0.7.2]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.6.2...v0.7.0
[0.6.2]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/joe1chen/mongoid_taggable_with_context/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/joe1chen/mongoid_taggable_with_context/releases/tag/v0.1.0
