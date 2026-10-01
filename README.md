# mongoid_taggable_with_context

[![CI RSpec Test](https://github.com/joe1chen/mongoid_taggable_with_context/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/joe1chen/mongoid_taggable_with_context/actions/workflows/test.yml)

Tagging for **Mongoid** documents with any number of independent tag *contexts* (e.g. `tags`, `skills`,
`interests`) per model, each stored as an array field, plus optional tag-count aggregation (tag clouds) kept
up to date in real time with `$inc`, or rebuilt with the aggregation pipeline or map-reduce.

This is the [DOGOnews](https://www.dogonews.com)-maintained fork of
[lgs/mongoid_taggable_with_context](https://github.com/lgs/mongoid_taggable_with_context) (inactive since
August 2017; not archived), itself a fork of Aaron Qian's original
[aq1018/mongoid_taggable_with_context](https://github.com/aq1018/mongoid_taggable_with_context) (inactive since
2013). It is kept working on current Ruby, Rails, Mongoid and MongoDB versions.

## Supported versions

Tested on every push by the [GitHub Actions matrix](https://github.com/joe1chen/mongoid_taggable_with_context/actions/workflows/test.yml)
([workflow](.github/workflows/test.yml)), with all four aggregation strategies:

| Ruby | Rails | Mongoid | MongoDB |
|---|---|---|---|
| 2.7 | 6.1 | 7.5 | 6.0 |
| 3.0 | 6.1 | 8.0 | 6.0 |
| 3.1 | 7.0 | 8.1 | 7.0 |
| 3.2 | 7.1 | 8.1 | 7.0 |
| 3.2 | 7.2 | 9.0 | 7.0 |
| 3.3 | 7.2 | 9.0 | 8.0 |
| 3.4 | 8.0 | 9.0 | 8.0 |

The gemspec allows `mongoid >= 7.0, < 10`.

## Installation

This fork is not published to RubyGems; install it from GitHub, pinned to a release tag
([releases](https://github.com/joe1chen/mongoid_taggable_with_context/releases)):

```ruby
# Gemfile
gem 'mongoid_taggable_with_context', github: 'joe1chen/mongoid_taggable_with_context', tag: 'v2.0.0'
```

## Usage

### Declare tag contexts

```ruby
class Post
  include Mongoid::Document
  include Mongoid::TaggableWithContext

  taggable                                    # context :tags, separator ' '
  taggable :skills, separator: ','            # context :skills
  taggable :ints, as: :interests              # context :interests, stored in the database field "ints"
  taggable :keywords, default: ['foobar']     # other Mongoid field options (:default, :as, :localize, ...) pass through
end
```

`taggable [field], options` creates an `Array` field (and an index on it). Options:

- `separator:` — delimiter used to split/join tag strings (default `' '`).
- `as:` — name of the context when it differs from the database field name.
- `group_by_field:` — the field to group by, for the `RealTimeGroupBy` strategy.
- any option accepted by Mongoid's `field` (`type` is always `Array`).

### Instance methods

For a context `tags`:

```ruby
post.tags = "food ant bee"        # a separated String or an Array
post.tags = %w[food ant bee]
post.tags                         # => ["food", "ant", "bee"]  (stripped, blanks and duplicates removed)
post.tags_string                  # => "food ant bee"
post.tags_string = "x y"          # same as post.tags = "x y"
```

### Querying

```ruby
Post.tagged_with(:tags, "food bee")       # documents having ALL the given tags (String or Array)
Post.tags_tagged_with(%w[food bee])       # same, per-context shortcut
Post.skills_separator                     # => ","
Post.tag_contexts                         # => [:tags, :skills, :interests, :keywords]
```

### Aggregation strategies

Include one strategy to get tag lists and weights (counts) per context. Each strategy keeps the counts in a
collection named `<collection>_<context>_aggregation`.

| Strategy | How counts are maintained |
|---|---|
| `AggregationStrategy::RealTime` | `$inc` on every save/destroy — constant cost as data grows (recommended) |
| `AggregationStrategy::RealTimeGroupBy` | `RealTime` plus per-group counts (by `group_by_field`) |
| `AggregationStrategy::Aggregation` | full `$group`/`$out` aggregation pipeline after each save that changes tags |
| `AggregationStrategy::MapReduce` | full map-reduce after each save that changes tags (`mapReduce` is deprecated by MongoDB) |

```ruby
class Post
  include Mongoid::Document
  include Mongoid::TaggableWithContext
  include Mongoid::TaggableWithContext::AggregationStrategy::RealTime

  taggable
  taggable :skills, separator: ','
end

Post.create!(tags: "food ant bee")
Post.create!(tags: "juice food bee zip")
Post.create!(tags: "honey strip food")

Post.tags              # => ["ant", "bee", "food", "honey", "juice", "strip", "zip"]
Post.tags_with_weight  # => [["ant", 1], ["bee", 2], ["food", 3], ["honey", 1], ["juice", 1], ["strip", 1], ["zip", 1]]

# optional conditions on the aggregation collection, plus :limit and :sort
Post.tags_with_weight(nil, limit: 2, sort: { value: -1 })   # => [["food", 3], ["bee", 2]]
```

`RealTime` (and `RealTimeGroupBy`) also provide:

```ruby
Post.tags_autocomplete(:tags, "f")                               # => [["food", 3]]  tags starting with "f"
Post.tags_autocomplete(:tags, "b", sort_by_count: true, max: 10)
Post.recalculate_tag_weights!(:tags)                             # rebuild one context's counts from the documents
Post.recalculate_all_context_tag_weights!                        # rebuild every context (uses map-reduce)
```

#### Group-by counts

```ruby
class Post
  include Mongoid::Document
  include Mongoid::TaggableWithContext
  include Mongoid::TaggableWithContext::AggregationStrategy::RealTimeGroupBy

  field :user
  taggable group_by_field: :user
end

Post.create!(user: "u1", tags: "a b")
Post.create!(user: "u2", tags: "b c")

Post.tags                    # => ["a", "b", "c"]
Post.tags("u1")              # => ["a", "b"]
Post.tags_with_weight("u2")  # => [["b", 1], ["c", 1]]
Post.tags_group_by_field     # => :user
```

Without an aggregation strategy, `Post.tags` / `Post.tags_with_weight` raise
`Mongoid::TaggableWithContext::AggregationStrategyMissing`.

## Development

```bash
# needs a MongoDB on localhost:27017 (e.g. docker run -p 27017:27017 mongo:8.0)
MONGOID_VERSION=9.0 RAILS_VERSION=8.0 bundle install
MONGOID_VERSION=9.0 RAILS_VERSION=8.0 bundle exec rspec spec
```

`MONGOID_VERSION` and `RAILS_VERSION` select the versions in the `Gemfile` (defaults: Mongoid 7.5, Rails 6.1 —
what dogo-web runs today). To add a combination to CI, add a row to `matrix.include` in
`.github/workflows/test.yml`.

## Known issues

- `MapReduce` (and `RealTime.recalculate_tag_weights!`) use MongoDB's `mapReduce` command, which is deprecated
  since MongoDB 5.0 but still works on 8.0 (tested). Prefer `RealTime` or `Aggregation` for new code.
- `tags_autocomplete` interpolates its prefix into a regular expression unescaped, so regex metacharacters in user
  input are interpreted (escape with `Regexp.escape` before calling if the prefix comes from users).

## History

Aaron Qian's original (2011, based on mongoid_taggable by Wilker Lúcio and Ches Martin) was continued by
lgs through 1.1.4 (2013: aliased contexts, `RealTimeGroupBy`) and by DOGOnews in this fork: 1.1.5–1.1.6
(Mongoid 2 and 4–6 support, `:sort`/`:limit` conditions), then 2.0.0 (2026: Mongoid 7.0–9.x on current
Ruby/Rails/MongoDB, the `Aggregation` strategy, and fixes for `RealTime` with aliased contexts).
See [CHANGELOG.md](CHANGELOG.md).

## Credits

Aaron Qian, Luca G. Soave, John Shields, Wilker Lúcio, Ches Martin, and
[contributors](https://github.com/joe1chen/mongoid_taggable_with_context/graphs/contributors).

Copyright (c) 2011 Aaron Qian. Licensed under the MIT license (see [LICENSE.txt](LICENSE.txt)).
