# 0.4.7

* Deprecation warning for nilify options for dry-v >= 1.x
* Fix initializer struct when using `false` as value

# 0.4.6

* Remove deprecation warnings for newer versions of dry-types
* Fix sqlite3 version to 1.3.x to avoid issue with AR 5.0
* Raise an error if class is used as property name

# 0.4.5

* Use Gem::Version to detect version for dry-types

# 0.4.4

* Add support for Dry::Types version 0.13

# 0.4.3

* Fix `NoMethodError: private method `property' called for MyForm:Class in Reform.` by using `class_eval`.

# 0.4.2

* `Twin#schema` doesn't `extend` at runtime anymore but uses a decorator for `each`.
* `PropertyProcessor` now yields `(twin, index)` if its working on a collection.

# 0.4.1

* Allow `false` as a `:default` value.
* Use `Declarative::Builder` instead of `Uber::Builder`.

# 0.4.0

* In `#sync {}` with block, `nil` values will now be included in the nested hash, resulting in a hash as follows.
    ```ruby
    twin.sync do |nested_hash|
      nested_hash #=> {  uuid: nil, title: "Greatest Hits" }
    ```
  Note that in earlier versions, `nil` values were not included in this hash.

# 0.3.2

* Rename `JSONB` to `Property::Hash`.
* Fix `::unnest` so it copies delegated property options correctly.
* Deprecate `Twin::Struct`.

# 0.3.1

* Introduce `Twin::JSONB` for easy access to hash fields using `Struct`.

# 0.3.0

* Use [dry-types](https://github.com/dry-rb/dry-types) as a replacement for the deprecated virtus. You have to change to dry-types' constants.
* Add `:nilify` option to avoid processing blank strings.

# 0.2.6

* Manual accessors are no longer overridden when inheriting twin classes.
* The `:from` option is no longer ignored when inheriting.

# 0.2.5

* Fix loading order, you may now `require "disposable/twin"` without any further requires.

# 0.2.4

* Add `Twin::Parent` to access a nested's parent twin.
* Introduce `Twin#build_for` and `Twin#build_twin`. This is a private API change.

# 0.2.3

* Add `Collection#find_by` for easier traversal/querying of twin collections: `album.songs.find_by(id: 1)`.
* Fix inheritance of the `:default` option. This would formerly wrap the default value into another `Uber::Options::Value`.
* Introduce `Struct#save!`.

# 0.2.2

* Use `Uber::Options::Value#call` to evaluate.
* Add `Twin::Collection#append`.

# 0.2.1

* In `Callback::Group#call`, the `context` option now allows running callbacks in different contexts. Per default, the group instance is context.
* Callback handler methods now receive two options: the twin and the options hash passed into `Group#call`. This allows injecting arbitrary objects into callbacks, which is pretty awesome!

# 0.2.0

* Internally, use [Declarative](https://github.com/apotonick/declarative) now for schema creation, resulting in the following internal changes.
    * `Twin::representer_class.representable_attrs` is now `Twin::definitions`.
* `Disposable::Twin::Schema` is now `Disposable::Rescheme`. Renamed its `:representer_from` option to `:definitions_from`.
* `twin: Twin::Song` is the only way to specify an external twin. To reduce complexity, I've removed the lambda version of `:twin`.
* Added `:exclude_properties` to `Rescheme`.
* Runs with Representable 2.4 and 3.0.

# 0.1.15

* Restrict to Representable < 2.4.

# 0.1.14

* Allow to nil-out nested twins.

# 0.1.13

* Allow representable ~> 2.2.

# 0.1.12

* Added `Twin::for_collection`. Thanks to @timoschilling for the implementation.

# 0.1.11

* `:default` now accepts lambdas, too. Thanks to @johndagostino for implementing this.

# 0.1.10

* yanked.

# 0.1.9

* The `:twin` option is no longer evaluated at compile time, only inline twins are run through `::process_inline!`. This allows specifying twin classes in lambdas for lazy-loading, and recursive twins.

# 0.1.8

* Specifying a nested twin with `:twin` instead of a block now gets identically processed to the block.

# 0.1.7

* Removed Setup#merge_options! and hash merge as this is already been done in #setup_properties.
* Every property now gets set on the twin, even if `readable: false` is set.
* `:default` and `:virtual` now work together.
* Introduced `Setup#setup_property!`.

# 0.1.6

* Added `Default`.

# 0.1.5

* Correctly merge options from constructor into `@fields`.
* Add `:virtual` which is an alias for `readable: false, writeable: false`.
* Do not use getters with `SkipGetter` in `#sync{}`.

# 0.1.4

* Add `Twin::Coercion`.

# 0.1.3

* Fix `Composition#save`, it now returns true only if all models could be saved.
* Introduce `Callback::Group::clone`.

# 0.1.2

* Fix `Changed` which does not use the public reader to compare anymore, but the private `field_read`.

# 0.1.1

* Adding `Setup::SkipSetter` and `Sync::SkipGetter`.

# 0.1.0

* This is the official first serious release.

# 0.0.9

* Rename `:as` to `:from`. Deprecated, this will be removed in 0.1.0.

# 0.0.8

* Introduce the `Twin::Builder` module to easily allow creating a twin in a host object's constructor.

# 0.0.7

* Make disposable require representable 2.x.

# 0.0.6

* Add Twin::Option.

# 0.0.4

* Added `Composition#[]` to access contained models in favor of reader methods to models. The latter got removed. This allows mapping methods with the same name than the contained object.
