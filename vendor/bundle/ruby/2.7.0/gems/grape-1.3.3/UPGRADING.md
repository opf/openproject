Upgrading Grape
===============

### Upgrading to >= 1.4.0

#### Nil values for structures

Nil values always been a special case when dealing with types especially with the following structures:
 - Array
 - Hash
 - Set
 
The behaviour for these structures has change through out the latest releases. For instance:

```ruby
class Api < Grape::API
  params do
    require :my_param, type: Array[Integer]
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { my_param: nil }
  # 1.3.1 = []
  # 1.3.2 = nil
end
```
For now on, `nil` values stay `nil` values for all types, including arrays, sets and hashes.

If you want to have the same behavior as 1.3.1, apply a `default` validator

```ruby
class Api < Grape::API
  params do
    require :my_param, type: Array[Integer], default: []
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { my_param: nil } # => []
end
```

#### Default validator

Default validator is now applied for `nil` values.

```ruby
class Api < Grape::API
  params do
    requires :my_param, type: Integer, default: 0
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { my_param: nil } #=> before: nil, after: 0
end
```

### Upgrading to >= 1.3.0

#### Ruby

After adding dry-types, Ruby 2.4 or newer is required.

#### Coercion

[Virtus](https://github.com/solnic/virtus) has been replaced by
[dry-types](https://dry-rb.org/gems/dry-types/1.2/) for parameter
coercion. If your project depends on Virtus outside of Grape, explicitly
add it to your `Gemfile`.

Here's an example of how to migrate a custom type from Virtus to dry-types:

```ruby
# Legacy Grape parser
class SecureUriType < Virtus::Attribute
  def coerce(input)
    URI.parse value
  end

  def value_coerced?(input)
    value.is_a? String
  end
end

params do
  requires :secure_uri, type: SecureUri
end
```

To use dry-types, we need to:

1. Remove the inheritance of `Virtus::Attribute`
1. Rename `coerce` to `self.parse`
1. Rename `value_coerced?` to `self.parsed?`

The custom type must have a class-level `parse` method to the model. A
class-level `parsed?` is needed if the parsed type differs from the
defined type. In the example below, since `SecureUri` is not the same
as `URI::HTTPS`, `self.parsed?` is needed:

```ruby
# New dry-types parser
class SecureUri
  def self.parse(value)
    URI.parse value
  end

  def self.parsed?(value)
    value.is_a? URI::HTTPS
  end
end

params do
  requires :secure_uri, type: SecureUri
end
```

#### Ensure that Array types have explicit coercions

Unlike Virtus, dry-types does not perform any implict coercions. If you
have any uses of `Array[String]`, `Array[Integer]`, etc. be sure they
use a `coerce_with` block. For example:

```ruby
requires :values, type: Array[String]
```

It's quite common to pass a comma-separated list, such as `tag1,tag2` as
`values`. Previously Virtus would implicitly coerce this to
`Array(values)` so that `["tag1,tag2"]` would pass the type checks, but
with `dry-types` the values are no longer coerced for you. To fix this,
you might do:

```ruby
requires :values, type: Array[String], coerce_with: ->(val) { val.split(',').map(&:strip) }
```

Likewise, for `Array[Integer]`, you might do:

```ruby
requires :values, type: Array[Integer], coerce_with: ->(val) { val.split(',').map(&:strip).map(&:to_i) }
```

For more information see [#1920](https://github.com/ruby-grape/grape/pull/1920).

### Upgrading to >= 1.2.4

#### Headers in `error!` call

Headers in `error!` will be merged with `headers` hash. If any header need to be cleared on `error!` call, make sure to move it to the `after` block.

```ruby
class SampleApi < Grape::API
  before do
    header 'X-Before-Header', 'before_call'
  end

  get 'ping' do
    header 'X-App-Header', 'on_call'
    error! :pong, 400, 'X-Error-Details' => 'Invalid token'
  end
end
```
**Former behaviour**
```ruby
  response.headers['X-Before-Header'] # => nil
  response.headers['X-App-Header'] # => nil
  response.headers['X-Error-Details'] # => Invalid token
```

**Current behaviour**
```ruby
  response.headers['X-Before-Header'] # => 'before_call'
  response.headers['X-App-Header'] # => 'on_call'
  response.headers['X-Error-Details'] # => Invalid token
```

### Upgrading to >= 1.2.1

#### Obtaining the name of a mounted class

In order to make obtaining the name of a mounted class simpler, we've delegated `.to_s` to `base.name`

**Deprecated in 1.2.0**
```ruby
  payload[:endpoint].options[:for].name
```
**New**
```ruby
  payload[:endpoint].options[:for].to_s
```

### Upgrading to >= 1.2.0

#### Changes in the Grape::API class

##### Patching the class

In an effort to make APIs re-mountable, The class `Grape::API` no longer refers to an API instance,
rather, what used to be `Grape::API` is now `Grape::API::Instance` and `Grape::API` was replaced
with a class that can contain several instances of `Grape::API`.

This changes were done in such a way that no code-changes should be required.
However, if experiencing problems, or relying on private methods and internal behaviour too deeply, it is possible to restore the prior behaviour by replacing the references from `Grape::API` to `Grape::API::Instance`.

Note, this is particularly relevant if you are opening the class `Grape::API` for modification.

**Deprecated**
```ruby
class Grape::API
  # your patched logic
  ...
end
```
**New**
```ruby
class Grape::API::Instance
  # your patched logic
  ...
end
```

##### `name` (and other caveats) of the mounted API

After the patch, the mounted API is no longer a Named class inheriting from `Grape::API`, it is an anonymous class
which inherit from `Grape::API::Instance`.
What this means in practice, is:
- Generally: you can access the named class from the instance calling the getter `base`.
- In particular: If you need the `name`, you can use `base`.`name`

**Deprecated**
```ruby
  payload[:endpoint].options[:for].name
```
**New**
```ruby
  payload[:endpoint].options[:for].base.name
```

#### Changes in rescue_from returned object

Grape will now check the object returned from `rescue_from` and ensure that it is a `Rack::Response`. That makes sure response is valid and avoids exposing service information. Change any code that invoked `Rack::Response.new(...).finish` in a custom `rescue_from` block to `Rack::Response.new(...)` to comply with the validation.

```ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    # version prior to 1.2.0
    Rack::Response.new([ e.message ], 500, { 'Content-type' => 'text/error' }).finish
    # 1.2.0  version
    Rack::Response.new([ e.message ], 500, { 'Content-type' => 'text/error' })
  end
end
```

See [#1757](https://github.com/ruby-grape/grape/pull/1757) and [#1776](https://github.com/ruby-grape/grape/pull/1776) for more information.

### Upgrading to >= 1.1.0

#### Changes in HTTP Response Code for Unsupported Content Type

For PUT, POST, PATCH, and DELETE requests where a non-empty body and a "Content-Type" header is supplied that is not supported by the Grape API, Grape will no longer return a 406 "Not Acceptable" HTTP status code and will instead return a 415 "Unsupported Media Type" so that the usage of HTTP status code falls more in line with the specification of [RFC 2616](https://www.ietf.org/rfc/rfc2616.txt).

### Upgrading to >= 1.0.0

#### Changes in XML and JSON Parsers

Grape no longer uses `multi_json` or `multi_xml` by default and uses `JSON` and `ActiveSupport::XmlMini` instead. This has no visible impact on JSON processing, but the default behavior of the XML parser has changed. For example, an XML POST containing `<user>Bobby T.</user>` was parsed as `Bobby T.` with `multi_xml`, and as now parsed as `{"__content__"=>"Bobby T."}` with `XmlMini`.

If you were using `MultiJson.load`, `MultiJson.dump` or `MultiXml.parse`, you can substitute those with `Grape::Json.load`, `Grape::Json.dump`, `::Grape::Xml.parse`, or directly with `JSON.load`, `JSON.dump`, `XmlMini.parse`, etc.

To restore previous behavior, add `multi_json` or `multi_xml` to your `Gemfile` and `require` it.

See [#1623](https://github.com/ruby-grape/grape/pull/1623) for more information.

#### Changes in Parameter Class

The default class for `params` has changed from `Hashie::Mash` to `ActiveSupport::HashWithIndifferentAccess` and the `hashie` dependency has been removed. This means that by default you can no longer access parameters by method name.

```ruby
class API < Grape::API
  params do
    optional :color, type: String
  end
  get do
    params[:color] # use params[:color] instead of params.color
  end
end
```

To restore the behavior of prior versions, add `hashie` to your `Gemfile` and `include Grape::Extensions::Hashie::Mash::ParamBuilder` in your API.

```ruby
class API < Grape::API
  include Grape::Extensions::Hashie::Mash::ParamBuilder

  params do
    optional :color, type: String
  end
  get do
    # params.color works
  end
end
```

This behavior can also be overridden on individual parameter blocks using `build_with`.

```ruby
params do
  build_with Grape::Extensions::Hash::ParamBuilder
  optional :color, type: String
end
```

If you're constructing your own `Grape::Request` in a middleware, you can pass different parameter handlers to create the desired `params` class with `build_params_with`.

```ruby
def request
  Grape::Request.new(env, build_params_with: Grape::Extensions::Hashie::Mash::ParamBuilder)
end
```

See [#1610](https://github.com/ruby-grape/grape/pull/1610) for more information.

#### The `except`, `except_message`, and `proc` options of the `values` validator are deprecated.

The new `except_values` validator should be used in place of the `except` and `except_message` options of
the `values` validator.

Arity one Procs may now be used directly as the `values` option to explicitly test param values.

**Deprecated**
```ruby
params do
  requires :a, values: { value: 0..99, except: [3] }
  requires :b, values: { value: 0..99, except: [3], except_message: 'not allowed' }
  requires :c, values: { except: ['admin'] }
  requires :d, values: { proc: -> (v) { v.even? } }
end
```
**New**
```ruby
params do
  requires :a, values: 0..99, except_values: [3]
  requires :b, values: 0..99, except_values: { value: [3], message: 'not allowed' }
  requires :c, except_values: ['admin']
  requires :d, values: -> (v) { v.even? }
end
```

See [#1616](https://github.com/ruby-grape/grape/pull/1616) for more information.

### Upgrading to >= 0.19.1

#### DELETE now defaults to status code 200 for responses with a body, or 204 otherwise

Prior to this version, DELETE requests defaulted to a status code of 204 No Content, even when the response included content. This behavior confused some clients and prevented the formatter middleware from running properly. As of this version, DELETE requests will only default to a 204 No Content status code if no response body is provided, and will default to 200 OK otherwise.

Specifically, DELETE behaviour has changed as follows:

- In versions < 0.19.0, all DELETE requests defaulted to a 200 OK status code.
- In version 0.19.0, all DELETE requests defaulted to a 204 No Content status code, even when content was included in the response.
- As of version 0.19.1, DELETE requests default to a 204 No Content status code, unless content is supplied, in which case they default to a 200 OK status code.

To achieve the old behavior, one can specify the status code explicitly:

```ruby
delete :id do
  status 204 # or 200, for < 0.19.0 behavior
  'foo successfully deleted'
end
```

One can also use the new `return_no_content` helper to explicitly return a 204 status code and an empty body for any request type:

```ruby
delete :id do
  return_no_content
  'this will not be returned'
end
```

See [#1550](https://github.com/ruby-grape/grape/pull/1550) for more information.

### Upgrading to >= 0.18.1

#### Changes in priority of :any routes

Prior to this version, `:any` routes were searched after matching first route and 405 routes. This behavior has changed and `:any` routes are now searched before 405 processing. In the following example the `:any` route will match first when making a request with an unsupported verb.

```ruby
post :example do
  'example'
end
route :any, '*path' do
  error! :not_found, 404
end

get '/example' #=> before: 405, after: 404
```

#### Removed param processing from built-in OPTIONS handler

When a request is made to the built-in `OPTIONS` handler, only the `before` and `after`
callbacks associated with the resource will be run.  The `before_validation` and
`after_validation` callbacks and parameter validations will be skipped.

See [#1505](https://github.com/ruby-grape/grape/pull/1505) for more information.

#### Changed endpoint params validation

Grape now correctly returns validation errors for all params when multiple params are passed to a requires.
The following code will return `one is missing, two is missing` when calling the endpoint without parameters.

```ruby
params do
  requires :one, :two
end
```

Prior to this version the response would be `one is missing`.

See [#1510](https://github.com/ruby-grape/grape/pull/1510) for more information.

#### The default status code for DELETE is now 204 instead of 200.

Breaking change: Sets the default response status code for a delete request to 204.
A status of 204 makes the response more distinguishable and therefore easier to handle on the client side, particularly because a DELETE request typically returns an empty body as the resource was deleted or voided.

To achieve the old behavior, one has to set it explicitly:
```ruby
delete :id do
  status 200
  'foo successfully deleted'
end
```

For more information see: [#1532](https://github.com/ruby-grape/grape/pull/1532).

### Upgrading to >= 0.17.0

#### Removed official support for Ruby < 2.2.2

Grape is no longer automatically tested against versions of Ruby prior to 2.2.2. This is because of its dependency on activesupport which, with version 5.0.0, now requires at least Ruby 2.2.2.

See [#1441](https://github.com/ruby-grape/grape/pull/1441) for nmore information.

#### Changed priority of `rescue_from` clauses applying

The `rescue_from` clauses declared inside a namespace would take a priority over ones declared in the root scope.
This could possibly affect those users who use different `rescue_from` clauses in root scope and in namespaces.

See [#1405](https://github.com/ruby-grape/grape/pull/1405) for more information.

#### Helper methods injected inside `rescue_from` in middleware

Helper methods are injected inside `rescue_from` may cause undesirable effects. For example, definining a helper method called `error!` will take precendence over the built-in `error!` method and should be renamed.

See [#1451](https://github.com/ruby-grape/grape/issues/1451) for an example.

### Upgrading to >= 0.16.0

#### Replace rack-mount with new router

The `Route#route_xyz` methods have been deprecated since 0.15.1.

Please use `Route#xyz` instead.

Note that the `Route#route_method` was replaced by `Route#request_method`.

The following code would work correctly.

```ruby
TwitterAPI::versions # yields [ 'v1', 'v2' ]
TwitterAPI::routes # yields an array of Grape::Route objects
TwitterAPI::routes[0].version # => 'v1'
TwitterAPI::routes[0].description # => 'Includes custom settings.'
TwitterAPI::routes[0].settings[:custom] # => { key: 'value' }

TwitterAPI::routes[0].request_method # => 'GET'
```

#### `file` method accepts path to file

Now to serve files via Grape just pass the path to the file. Functionality with FileStreamer-like objects is deprecated.

Please, replace your FileStreamer-like objects with paths of served files.

Old style:

```ruby
class FileStreamer
  def initialize(file_path)
    @file_path = file_path
  end

  def each(&blk)
    File.open(@file_path, 'rb') do |file|
      file.each(10, &blk)
    end
  end
end

# ...

class API < Grape::API
  get '/' do
    file FileStreamer.new('/path/to/file')
  end
end
```

New style:

```ruby
class API < Grape::API
  get '/' do
    file '/path/to/file'
  end
end
```

### Upgrading to >= 0.15.0

#### Changes to availability of `:with` option of `rescue_from` method

The `:with` option of `rescue_from` does not accept value except Proc, String or Symbol now.

If you have been depending the old behavior, you should use lambda block instead.

```ruby
class API < Grape::API
  rescue_from :all, with: -> { Rack::Response.new('rescued with a method', 400) }
end
```

#### Changes to behavior of `after` method of middleware on error

The `after` method of the middleware is now also called on error. The following code would work correctly.

```ruby
class ErrorMiddleware < Grape::Middleware::Base
  def after
    return unless @app_response && @app_response[0] == 500
    env['rack.logger'].debug("Raised error on #{env['PATH_INFO']}")
  end
end
```

See [#1147](https://github.com/ruby-grape/grape/issues/1147) and [#1240](https://github.com/ruby-grape/grape/issues/1240) for discussion of the issues.

A warning will be logged if an exception is raised in an `after` callback, which points you to middleware that was not called in the previous version and is called now.

```
caught error of type NoMethodError in after callback inside Api::Middleware::SomeMiddleware : undefined method `headers' for nil:NilClass
```

See [#1285](https://github.com/ruby-grape/grape/pull/1285) for more information.

#### Changes to Method Not Allowed routes

A `405 Method Not Allowed` error now causes `Grape::Exceptions::MethodNotAllowed` to be raised, which will be rescued via `rescue_from :all`. Restore old behavior with the following error handler.

```ruby
rescue_from Grape::Exceptions::MethodNotAllowed do |e|
  error! e.message, e.status, e.headers
end
```

See [#1283](https://github.com/ruby-grape/grape/pull/1283) for more information.

#### Changes to Grape::Exceptions::Validation parameters

When raising `Grape::Exceptions::Validation` explicitly, replace `message_key` with `message`.

For example,

```ruby
fail Grape::Exceptions::Validation, params: [:oauth_token_secret], message_key: :presence
```

becomes

```ruby
fail Grape::Exceptions::Validation, params: [:oauth_token_secret], message: :presence
```

See [#1295](https://github.com/ruby-grape/grape/pull/1295) for more information.

### Upgrading to >= 0.14.0

#### Changes to availability of DSL methods in filters

The `#declared` method of the route DSL is no longer available in the `before` filter.  Using `declared` in a `before` filter will now raise `Grape::DSL::InsideRoute::MethodNotYetAvailable`.

See [#1074](https://github.com/ruby-grape/grape/issues/1074) for discussion of the issue.

#### Changes to header versioning and invalid header version handling

Identical endpoints with different versions now work correctly. A regression introduced in Grape 0.11.0 caused all but the first-mounted version for such an endpoint to wrongly throw an `InvalidAcceptHeader`. As a side effect, requests with a correct vendor but invalid version can no longer be rescued from a `rescue_from` block.

See [#1114](https://github.com/ruby-grape/grape/pull/1114) for more information.

#### Bypasses formatters when status code indicates no content

To be consistent with rack and it's handling of standard responses
associated with no content, both default and custom formatters will now
be bypassed when processing responses for status codes defined [by rack](https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L567)

See [#1190](https://github.com/ruby-grape/grape/pull/1190) for more information.

#### Redirects respond as plain text with message

`#redirect` now uses `text/plain` regardless of whether that format has
been enabled. This prevents formatters from attempting to serialize the
message body and allows for a descriptive message body to be provided - and
optionally overridden - that better fulfills the theme of the HTTP spec.

See [#1194](https://github.com/ruby-grape/grape/pull/1194) for more information.

### Upgrading to >= 0.12.0

#### Changes in middleware

The Rack response object is no longer converted to an array by the formatter, enabling streaming. If your custom middleware is accessing `@app_response`, update it to expect a `Rack::Response` instance instead of an array.

For example,

```ruby
class CacheBusterMiddleware < Grape::Middleware::Base
  def after
    @app_response[1]['Expires'] = Time.at(0).utc.to_s
    @app_response
  end
end
```

becomes

```ruby
class CacheBusterMiddleware < Grape::Middleware::Base
  def after
    @app_response.headers['Expires'] = Time.at(0).utc.to_s
    @app_response
  end
end
```

See [#1029](https://github.com/ruby-grape/grape/pull/1029) for more information.

There is a known issue because of this change. When Grape is used with an older
than 1.2.4 version of [warden](https://github.com/hassox/warden) there may be raised
the following exception having the [rack-mount](https://github.com/jm/rack-mount) gem's
lines as last ones in the backtrace:

```
NoMethodError: undefined method `[]' for nil:NilClass
```

The issue can be solved by upgrading warden to 1.2.4 version.

See [#1151](https://github.com/ruby-grape/grape/issues/1151) for more information.

#### Changes in present

Using `present` with objects that responded to `merge` would cause early evaluation of the represented object, with unexpected side-effects, such as missing parameters or environment within rendering code. Grape now only merges represented objects with a previously rendered body, usually when multiple `present` calls are made in the same route.

See [grape-with-roar#5](https://github.com/dblock/grape-with-roar/issues/5) and [#1023](https://github.com/ruby-grape/grape/issues/1023).

#### Changes to regexp validator

Parameters with `nil` value will now pass `regexp` validation. To disallow `nil` value for an endpoint, add `allow_blank: false`.

```ruby
params do
  requires :email, allow_blank: false, regexp: /.+@.+/
end
```

See [#957](https://github.com/ruby-grape/grape/pull/957) for more information.

#### Replace error_response with error! in rescue_from blocks

Note: `error_response` is being deprecated, not removed.

```ruby
def error!(message, status = options[:default_status], headers = {}, backtrace = [])
  headers = { 'Content-Type' => content_type }.merge(headers)
  rack_response(format_message(message, backtrace), status, headers)
end
```

For example,

```
error_response({ message: { message: 'No such page.', id: 'missing_page' }, status: 404, headers: { 'Content-Type' => 'api/error' })
```

becomes

```
error!({ message: 'No such page.', id: 'missing_page' }, 404, { 'Content-Type' => 'api/error' })
```

`error!` also supports just passing a message. `error!('Server error.')` and `format: :json` returns the following JSON response

```
{ 'error': 'Server error.' }
```

with a status code of 500 and a Content Type of text/error.

Optionally, also replace `Rack::Response.new` with `error!.`
The following are equivalent:

```
Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" }).finish
error!(e)
```

See [#889](https://github.com/ruby-grape/grape/issues/889) for more information.

#### Changes to routes when using `format`

Version 0.10.0 has introduced a change via [#809](https://github.com/ruby-grape/grape/pull/809) whereas routes no longer got file-type suffixes added if you declared a single API `format`. This has been reverted, it's now again possible to call API with proper suffix when single `format` is defined:

```ruby
class API < Grape::API
  format :json

  get :hello do
    { hello: 'world' }
  end
end
```

Will respond with JSON to `/hello` **and** `/hello.json`.

Will respond with 404 to `/hello.xml`, `/hello.txt` etc.

See the [#1001](https://github.com/ruby-grape/grape/pull/1001) and [#914](https://github.com/ruby-grape/grape/issues/914) for more info.

### Upgrading to >= 0.11.0

#### Added Rack 1.6.0 support

Grape now supports, but doesn't require Rack 1.6.0. If you encounter an issue with parsing requests larger than 128KB, explictly require Rack 1.6.0 in your Gemfile.

```ruby
gem 'rack', '~> 1.6.0'
```

See [#559](https://github.com/ruby-grape/grape/issues/559) for more information.

#### Removed route_info

Key route_info is excluded from params.

See [#879](https://github.com/ruby-grape/grape/pull/879) for more information.


#### Fix callbacks within a version block

Callbacks defined in a version block are only called for the routes defined in that block. This was a regression introduced in Grape 0.10.0, and is fixed in this version.

See [#901](https://github.com/ruby-grape/grape/pull/901) for more information.


#### Make type of group of parameters required

Groups of parameters now require their type to be set explicitly as Array or Hash.
Not setting the type now results in MissingGroupTypeError, unsupported type will raise UnsupportedTypeError.

See [#886](https://github.com/ruby-grape/grape/pull/886) for more information.

### Upgrading to >= 0.10.1

#### Changes to `declared(params, include_missing: false)`

Attributes with `nil` values or with values that evaluate to `false` are no longer considered *missing* and will be returned when `include_missing` is set to `false`.

See [#864](https://github.com/ruby-grape/grape/pull/864) for more information.

### Upgrading to >= 0.10.0

#### Changes to content-types

The following content-types have been removed:

* atom (application/atom+xml)
* rss (application/rss+xml)
* jsonapi (application/jsonapi)

This is because they have never been properly supported.

#### Changes to desc

New block syntax:

Former:

```ruby
  desc "some descs",
    detail: 'more details',
    entity: API::Entities::Entity,
    params: API::Entities::Status.documentation,
    named: 'a name',
    headers: [XAuthToken: {
      description: 'Valdates your identity',
      required: true
    }
  get nil, http_codes: [
    [401, 'Unauthorized', API::Entities::BaseError],
    [404, 'not found', API::Entities::Error]
  ] do
```

Now:

```ruby
desc "some descs" do
  detail 'more details'
  params API::Entities::Status.documentation
  success API::Entities::Entity
  failure [
    [401, 'Unauthorized', API::Entities::BaseError],
    [404, 'not found', API::Entities::Error]
  ]
  named 'a name'
  headers [
    XAuthToken: {
      description: 'Valdates your identity',
      required: true
    },
    XOptionalHeader: {
      description: 'Not really needed',
      required: false
    }
  ]
end
```

#### Changes to Route Options and Descriptions

A common hack to extend Grape with custom DSL methods was manipulating `@last_description`.

``` ruby
module Grape
  module Extensions
    module SortExtension
      def sort(value)
        @last_description ||= {}
        @last_description[:sort] ||= {}
        @last_description[:sort].merge! value
        value
      end
    end

    Grape::API.extend self
  end
end
```

You could access this value from within the API with `route.route_sort` or, more generally, via `env['api.endpoint'].options[:route_options][:sort]`.

This will no longer work, use the documented and supported `route_setting`.

``` ruby
module Grape
  module Extensions
    module SortExtension
      def sort(value)
        route_setting :sort, sort: value
        value
      end
    end

    Grape::API.extend self
  end
end
```

To retrieve this value at runtime from within an API, use `env['api.endpoint'].route_setting(:sort)` and when introspecting a mounted API, use `route.route_settings[:sort]`.

#### Accessing Class Variables from Helpers

It used to be possible to fetch an API class variable from a helper function. For example:

```ruby
@@static_variable = 42

helpers do
  def get_static_variable
    @@static_variable
  end
end

get do
  get_static_variable
end
```

This will no longer work. Use a class method instead of a helper.

```ruby
@@static_variable = 42

def self.get_static_variable
  @@static_variable
end

get do
  get_static_variable
end
```

For more information see [#836](https://github.com/ruby-grape/grape/issues/836).

#### Changes to Custom Validators

To implement a custom validator, you need to inherit from `Grape::Validations::Base` instead of `Grape::Validations::Validator`.

For more information see [Custom Validators](https://github.com/ruby-grape/grape#custom-validators) in the documentation.

#### Changes to Raising Grape::Exceptions::Validation

In previous versions raising `Grape::Exceptions::Validation` required a single `param`.

```ruby
raise Grape::Exceptions::Validation, param: :id, message_key: :presence
```

The `param` argument has been deprecated and is now an array of `params`, accepting multiple values.

```ruby
raise Grape::Exceptions::Validation, params: [:id], message_key: :presence
```

#### Changes to routes when using `format`

Routes will no longer get file-type suffixes added if you declare a single API `format`. For example,

```ruby
class API < Grape::API
  format :json

  get :hello do
    { hello: 'world' }
  end
end
```

Pre-0.10.0, this would respond with JSON to `/hello`, `/hello.json`, `/hello.xml`, `/hello.txt`, etc.

Now, this will only respond with JSON to `/hello`, but will be a 404 when trying to access `/hello.json`, `/hello.xml`, `/hello.txt`, etc.

If you declare further `content_type`s, this behavior will be circumvented. For example, the following API will respond with JSON to `/hello`, `/hello.json`, `/hello.xml`, `/hello.txt`, etc.

```ruby
class API < Grape::API
  format :json
  content_type :json, 'application/json'

  get :hello do
    { hello: 'world' }
  end
end
```

See the [the updated API Formats documentation](https://github.com/ruby-grape/grape#api-formats) and [#809](https://github.com/ruby-grape/grape/pull/809) for more info.

#### Changes to Evaluation of Permitted Parameter Values

Permitted and default parameter values are now only evaluated lazily for each request when declared as a proc. The following code would raise an error at startup time.

```ruby
params do
  optional :v, values: -> { [:x, :y] }, default: -> { :z }
end
```

Remove the proc to get the previous behavior.

```ruby
params do
  optional :v, values: [:x, :y], default: :z
end
```

See [#801](https://github.com/ruby-grape/grape/issues/801) for more information.

#### Changes to version

If version is used with a block, the callbacks defined within that version block are not scoped to that individual block. In other words, the callback would be inherited by all versions blocks that follow the first one e.g

```ruby
class API < Grape::API
  resource :foo do
    version 'v1', :using => :path do
      before do
        @output ||= 'hello1'
      end
      get '/' do
        @output += '-v1'
      end
    end

    version 'v2', :using => :path do
      before do
        @output ||= 'hello2'
      end
      get '/:id' do
        @output += '-v2'
      end
    end
  end
end
```

when making a API call `GET /foo/v2/1`, the API would set instance variable `@output` to `hello1-v2`

See [#898](https://github.com/ruby-grape/grape/issues/898) for more information.


### Upgrading to >= 0.9.0

#### Changes in Authentication

The following middleware classes have been removed:

* `Grape::Middleware::Auth::Basic`
* `Grape::Middleware::Auth::Digest`
* `Grape::Middleware::Auth::OAuth2`

When you use theses classes directly like:

```ruby
 module API
   class Root < Grape::API
     class Protected < Grape::API
       use Grape::Middleware::Auth::OAuth2,
           token_class: 'AccessToken',
           parameter: %w(access_token api_key)

```

you have to replace these classes.

As replacement can be used

* `Grape::Middleware::Auth::Basic`  => [`Rack::Auth::Basic`](https://github.com/rack/rack/blob/master/lib/rack/auth/basic.rb)
* `Grape::Middleware::Auth::Digest` => [`Rack::Auth::Digest::MD5`](https://github.com/rack/rack/blob/master/lib/rack/auth/digest/md5.rb)
* `Grape::Middleware::Auth::OAuth2` => [warden-oauth2](https://github.com/opperator/warden-oauth2) or [rack-oauth2](https://github.com/nov/rack-oauth2)

If this is not possible you can extract the middleware files from [grape v0.7.0](https://github.com/ruby-grape/grape/tree/v0.7.0/lib/grape/middleware/auth)
and host these files within your application

See [#703](https://github.com/ruby-grape/Grape/pull/703) for more information.

### Upgrading to >= 0.7.0

#### Changes in Exception Handling

Assume you have the following exception classes defined.

```ruby
class ParentError < StandardError; end
class ChildError < ParentError; end
```

In Grape <= 0.6.1, the `rescue_from` keyword only handled the exact exception being raised. The following code would rescue `ParentError`, but not `ChildError`.

```ruby
rescue_from ParentError do |e|
  # only rescue ParentError
end
```

This made it impossible to rescue an exception hieararchy, which is a more sensible default. In Grape 0.7.0 or newer, both `ParentError` and `ChildError` are rescued.

```ruby
rescue_from ParentError do |e|
  # rescue both ParentError and ChildError
end
```

To only rescue the base exception class, set `rescue_subclasses: false`.

```ruby
rescue_from ParentError, rescue_subclasses: false do |e|
  # only rescue ParentError
end
```

See [#544](https://github.com/ruby-grape/grape/pull/544) for more information.


#### Changes in the Default HTTP Status Code

In Grape <= 0.6.1, the default status code returned from `error!` was 403.

```ruby
error! "You may not reticulate this spline!" # yields HTTP error 403
```

This was a bad default value, since 403 means "Forbidden". Change any call to `error!` that does not specify a status code to specify one. The new default value is a more sensible default of 500, which is "Internal Server Error".

```ruby
error! "You may not reticulate this spline!", 403 # yields HTTP error 403
```

You may also use `default_error_status` to change the global default.

```ruby
default_error_status 400
```

See [#525](https://github.com/ruby-grape/Grape/pull/525) for more information.


#### Changes in Parameter Declaration and Validation

In Grape <= 0.6.1, `group`, `optional` and `requires` keywords with a block accepted either an `Array` or a `Hash`.

```ruby
params do
  requires :id, type: Integer
  group :name do
    requires :first_name
    requires :last_name
  end
end
```

This caused the ambiguity and unexpected errors described in [#543](https://github.com/ruby-grape/Grape/issues/543).

In Grape 0.7.0, the `group`, `optional` and `requires` keywords take an additional `type` attribute which defaults to `Array`. This means that without a `type` attribute, these nested parameters will no longer accept a single hash, only an array (of hashes).

Whereas in 0.6.1 the API above accepted the following json, it no longer does in 0.7.0.

```json
{
  "id": 1,
  "name": {
    "first_name": "John",
    "last_name" : "Doe"
  }
}
```

The `params` block should now read as follows.

```ruby
params do
  requires :id, type: Integer
  requires :name, type: Hash do
    requires :first_name
    requires :last_name
  end
end
```

See [#545](https://github.com/ruby-grape/Grape/pull/545) for more information.


### Upgrading to 0.6.0

In Grape <= 0.5.0, only the first validation error was raised and processing aborted. Validation errors are now collected and a single `Grape::Exceptions::ValidationErrors` exception is raised. You can access the collection of validation errors as `.errors`.

```ruby
rescue_from Grape::Exceptions::Validations do |e|
  Rack::Response.new({
    status: 422,
    message: e.message,
    errors: e.errors
  }.to_json, 422)
end
```

For more information see [#462](https://github.com/ruby-grape/grape/issues/462).
