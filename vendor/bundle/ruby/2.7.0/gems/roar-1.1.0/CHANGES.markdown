# 1.1.0

* Require Representable 3.0.x
* Remove CollectionJSON support until we get more feedback.
* Move JSON API support (`Roar::JSON::JSONAPI`) to the separate [roar-jsonapi](https://github.com/trailblazer/roar-jsonapi) gem.
* When using `links[]`, you now need to provide the string name, as in `decorator.links["self"]`. Symbols are not supported, anymore.
* `::links` now accepts a String or Symbol as its first argument, enabling more straight-forward definition of CURIE links: e.g. `links 'doc:link_collection' do; end` (@edejong).
* Clients can now parse lonely collections. (@hilary)


# 1.0.4

* Require Representable < 2.4.

# 1.0.3

* Make `:as` work with `HAL`.

# 1.0.2

* Roar runs on Rubinius.

## JSON::HAL

* `"_embedded"` will always be rendered before `"_links"`.
* `render_nil: false` is now respected.

# 1.0.1

* Allow calling `::has_one`, `::links` and `::has_many` in any order in JSON API. This requires Representable >= 2.1.4.

# 1.0.0

## Breakage

* Removed `Representer` and `Feature` namespace. That means changes along the following.
    * `Roar::Representer::Feature::Hypermedia` --> `Roar::Hypermedia`
    * `Roar::Representer::JSON` --> `Roar::JSON`
* Removed positional arguments for `HttpVerbs#get` and friends.
* `HttpVerbs#get` and friends will now raise an exception when the response code is not 2xx. You can get the original response via `Roar::Transport::Error#response`. Thanks to @paulccarey for all his inspiring work and patience!

## Added

* `Roar::JSON::JSONAPI` supports JSON API. A big thanks to @oliverbarnes for his continuous help, support and research on how to implement this standard.

## Relevant

* `Hyperlink#to_hash` now returns stringified keys.
* Removed `Representer#before_serialize` hook. Override `#serialize` yourself.
* `Represented#links` now returns `nil` when no parsing has happened.
* Removed class methods `::from_json`, `::from_hash`, `::from_xml` and `::deserialize`. Please build the instance yourself and use something along `Song.new.from_json`.

## Internals

* Remove the concept of `links_array`. `Hyperlink` instances for rendering or that have been parsed are always stored in a `LinkCollection` that is available via `#links`.
* `Hypermedia` is now 43% simpler.
* `HyperlinkCollection#each` now has different semantics for 1- or 2-arity.

# 0.12.8

* Last release to support Representable < 2.0.

# 0.12.7

* Bug fix where hypermedia links were wrong when invoking serialization multiple times on the same instance.

# 0.12.6

* Remove deprecations (most of 'em) from Representable 1.8. Sorry for that.

# 0.12.5

* Roar runs with Representable <= 1.8.

# 0.12.4

* The `HAL` module supports [CURIE links](https://github.com/mikekelly/hal_specification/blob/f937dbc9f9e1fa25be824834794407fdcb8f116f/hal_specification.md#curies) now using the `::curie` method.
* Allow old and new API in HttpVerbs#get and friends.

# 0.12.3

* Allow basic authentication with `basic_auth: [:admin, :password]`.
* Allow HTTPS.
* Removed `NetHTTP#do_request`. It is in `NetHTTP::Request` now.

### Changes for `HttpVerbs#get` and friends:

* They now yield the request object to add headers etc before request is sent.
* They NO LONGER support positional arguments but one hash with `uri: "https://roar.de", body:, .. as: ..` and so on.

# 0.12.2

* Fix a bug where hyperlinks from nested objects weren't rendered in XML.

# 0.12.1

Allow Representable >= 1.6.

# 0.11.18

* Updating to Representable 1.5.2.

# 0.11.17

* Fixing HAL + Decorator.
* Requiring Representable 1.5.0.

# 0.11.16

* Added `Roar::Decorator::HypermediaConsumer` which propagates incoming hypermedia links to the represented object (it has to have accessors for `:links`).

# 0.11.15

* Fixing [#66](https://github.com/trailblazer/roar/issues/66).

# 0.11.14

* Fixing `Gemfile`.

# 0.11.13

* Adding `Roar::Decorator`, see [Representable docs](https://github.com/apotonick/Representable#decorator-vs-extend) for now.

# 0.11.12

* Moved `::inheritable_array` from `Hypermedia` to `Representer`.

# 0.11.11

* Allow use of `::link(string)`.

# 0.11.10

* Fix a syntax error for Ruby 1.8.
* Store link definitions in `Representable_attrs(:links)` now and no longer in the `LinksDefinition` instance itself. removing `#links_definition` in favor of `#link_configs`.

# 0.11.9

* When using `Feature::Client` hyperlinks are no longer rendered in POST and PUT since we pass `links: false`.
* `Transport::NetHttp` now sets both `Accept:` and `Content-type:` header since Rails services seems to get confused.

# 0.11.8

* Fixed `JSON::HAL::Links` so that it keys links with `links` and not `_links`. The latter is still done by `JSON::HAL`.

# 0.11.7

* Maintenance release: Fixing the horrible bug fix from 0.11.6 and make it a bit less horrible.

# 0.11.6

* "Fixing" a bug where `links_definition_option` was missing when no link was set in a representer. Note that this is a quick and horrible bugfix and will soon be cleaned up.

# 0.11.5

* Introducing `HAL::links` method to map arrays of link objects in the HAL format. This completes the HAL/JSON specification.

# 0.11.4

* Links can now return a hash of attributes as `link :self do {:href => fruit_path(self), :title => "Yummy stuff"} end`.

# 0.11.3

* Fixed an installation issue under Windows.

# 0.11.2

* The request body in POST, PUT and PATCH is now actually sent in HttpVerbs. Thanks to @nleguen for finding this embarrassing bug. That's what happens when you don't have proper tests, kids!

# 0.11.1

* Since some users don't have access to my local hard-drive we now really require Representable 1.2.2.

# 0.11.0

* Using Representable 1.2.2 now. Be warned that in 1.2 parsing and rendering slightly changed. When a property is not found in the incoming document, it is ignored and thus might not be initialised in your represented model (empty collections are still set to an empty array). Also, the way `false` and `nil` values are rendered changed.

  Quoted from the Representable CHANGES file:

  * A property with false value will now be included in the rendered representation. Same applies to parsing, false values will now be included. That particularly means properties that used to be unset (i.e. nil) after parsing might be false now.
  * You can include nil values now in your representations since #property respects `:represent_nil => true`.

* The `:except` option was deprecated in favor of `:exclude`.
* Hyperlinks can now have arbitrary attributes.
  To render, just provide `#link` with the options

  ```ruby
  link :self, :title => "Mee!", "data-remote" => true
  ```

  When parsing, the options are available via `OpenStruct` compliant readers.

  ```ruby
  link = Hyperlink.from_json('{"rel":"self","data-url":"http://self"'})
  link.rel #=> "self"
  link.send("data-url") #=> "http://self"
  ```

# 0.10.2

* You can now pass values from outside to the render method (e.g. `#to_json`), they will be available as block parameters inside `#link`.

# 0.10.1

* Adding the Coercion feature.

# 0.10.0

* Requiring Representable 0.1.3.
* Added JSON-HAL support.
* Links are no longer rendered when `href` is `nil` or `false`.
* `Representer.link` class method now accepts either the `rel` value, only, or a hash of link attributes (defined in `Hypermedia::Hyperlink.params`), like `link :rel => :self, :title => "You're good" do..`
* API CHANGE: `Representer#links` no longer returns the `href` value but the link object. Use it like `object.links[:self].href` to retrieve the URL.
* `#from_json` won't throw an exception anymore when passed an empty json document.

# 0.9.2

* Using Representable 1.1.

# 0.9.1

* Removed `Representer#to_attributes` and `#from_attributes`.
* Using Representable 1.0.1 now.

# 0.9.0

* Using Representable 0.12.x.
* `Representer::Base` is now simply `Representer`.
* Removed all the class methods from `HttpVerbs` except for `get`.

# 0.8.3

* Maintenance release for Representable compat.

# 0.8.2

* Removing `restfulie` dependency - we now use `Net::HTTP`.

# 0.8.1

* Added the `:except` and `:include` options to `#from_*`.
