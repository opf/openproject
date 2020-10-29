# Roar

_Resource-Oriented Architectures in Ruby._

[![Gitter Chat](https://badges.gitter.im/trailblazer/chat.svg)](https://gitter.im/trailblazer/chat)
[![TRB Newsletter](https://img.shields.io/badge/TRB-newsletter-lightgrey.svg)](http://trailblazer.to/newsletter/)
[![Build Status](https://travis-ci.org/trailblazer/roar.svg?branch=master)](https://travis-ci.org/trailblazer/roar)
[![Gem Version](https://badge.fury.io/rb/roar.svg)](http://badge.fury.io/rb/roar)

## Table of Contents

  * [Introduction](#introduction)
  * [Representable](#representable)
  * [Installation](#installation)
    * [Dependencies](#dependencies)
  * [Defining Representers](#defining-representers)
  * [Rendering](#rendering)
  * [Parsing](#parsing)
  * [Module Representers](#module-representers)
  * [Collections](#collections)
  * [Nesting](#nesting)
  * [Inline Representer](#inline-representer)
  * [Syncing Objects](#syncing-objects)
  * [Coercion](#coercion)
  * [More Features](#more-features)
  * [Hypermedia](#hypermedia)
  * [Passing Options](#passing-options)
  * [Specify Decorator](#specify-decorator)
  * [Consuming Hypermedia](#consuming-hypermedia)
  * [Media Formats](#media-formats)
  * [HAL\-JSON](#hal-json)
    * [Hypermedia](#hypermedia-1)
    * [Nesting](#nesting-1)
  * [JSON API](#json-api)
  * [Client\-Side Support](#client-side-support)
  * [HTTP Support](#http-support)
    * [HTTPS](#https)
    * [Basic Authentication](#basic-authentication)
    * [Client SSL certificates](#client-ssl-certificates)
    * [Request customization](#request-customization)
    * [Error handling](#error-handling)
  * [XML](#xml)
  * [Support](#support)
  * [License](#license)

## Introduction

Roar is a framework for parsing and rendering REST documents. Nothing more.

Representers let you define your API document structure and semantics. They allow both rendering representations from your models _and_ parsing documents to update your Ruby objects. The bi-directional nature of representers make them interesting for both server and client usage.

Roar comes with built-in JSON, JSON-HAL and XML support. JSON API support is available via the [JSON API](https://github.com/trailblazer/roar-jsonapi) gem. Its highly modular architecture provides features like coercion, hypermedia, HTTP transport, client caching and more.

Roar is completely framework-agnostic and loves being used in web kits like Rails, Hanami, Sinatra, Roda, etc. If you use Rails, consider [roar-rails](https://github.com/apotonick/roar-rails) for an enjoyable integration.

## Representable

Roar is just a thin layer on top of the [representable](https://github.com/trailblazer/representable) gem. While Roar gives you a DSL and behaviour for creating hypermedia APIs, representable implements all the mapping functionality.

If in need for a feature, make sure to check the [representable API docs](https://github.com/trailblazer/representable) first.

## Installation

The roar gem runs with all Ruby versions >= 1.9.3.

```ruby
gem 'roar'
```

### Dependencies

Roar does not bundle dependencies for JSON and XML.

If you want to use JSON, add the following to your `Gemfile`:

```ruby
gem 'multi_json'
```

If you want to use XML, add the following to your `Gemfile`:

```ruby
gem 'nokogiri'
```


## Defining Representers

Let's see how representers work. They're fun to use.

```ruby
require 'roar/decorator'
require 'roar/json'

class SongRepresenter < Roar::Decorator
  include Roar::JSON

  property :title
end
```

API documents are defined using a decorator class. You can define plain attributes using the `::property` method.

Now let's assume we'd have `Song` which is an `ActiveRecord` class. Please note that Roar is not limited to ActiveRecord. In fact, it doesn't really care whether it's representing ActiveRecord, `Sequel::Model` or just an OpenStruct instance.

```ruby
class Song < ActiveRecord::Base
end
```

## Rendering

To render a document, you apply the representer to your model.

```ruby
song = Song.new(title: "Medicine Balls")

SongRepresenter.new(song).to_json #=> {"title":"Medicine Balls"}
```

Here, the `song` objects gets wrapped (or "decorated") by the decorator. It is treated as immutable - Roar won't mix in any behaviour.

## Parsing

The cool thing about representers is: they can be used for rendering and parsing. See how easy updating your model from a document is.

```ruby
song = Song.new(title: "Medicine Balls")

SongRepresenter.new(song).from_json('{"title":"Linoleum"}')
song.title #=> Linoleum
```

Unknown attributes in the parsed document are simply ignored, making half-baked solutions like `strong_parameters` redundant.


## Module Representers

**Module Representers are deprecated in Roar 1.1 and will be removed in Roar 2.0.**

In place of inheriting from `Roar::Decorator`, you can also extend a singleton object with a representer module. Decorators and module representers actually have identical features. You can parse, render, nest, go nuts with both of them.


```ruby
song = Song.new(title: "Fate")
song.extend(SongRepresenter)

song.to_json #=> {"title":"Fate"}
```

Here, the representer is injected into the actual model and gives us a new `#to_json` method.

This also works both ways.

```ruby
song = Song.new
song.extend(SongRepresenter)

song.from_json('{"title":"Fate"}')
song #=> {"title":"Fate"}
```

It's worth noting though that many people dislike `#extend` due to well-known performance issues and object pollution. As such this approach is no longer recommended. In this README we'll use decorators to illustrate this library.


## Collections

Roar (or rather representable) also allows mapping collections in documents.

```ruby
class SongRepresenter < Roar::Decorator
  include Roar::JSON

  property :title
  collection :composers
end
```

Where `::property` knows how to handle plain attributes, `::collection` does lists.

```ruby
song = Song.new(title: "Roxanne", composers: ["Sting", "Stu Copeland"])

SongRepresenter.new(song).to_json #=> {"title":"Roxanne","composers":["Sting","Stu Copeland"]}
```

And, yes, this also works for parsing: `from_json` will create and populate the array of the `composers` attribute.


## Nesting

Now what if we need to tackle with collections of `Song`s? We need to implement an `Album` class.

```ruby
class Album < ActiveRecord::Base
  has_many :songs
end
```

Another representer to represent.

```ruby
class AlbumRepresenter < Roar::Decorator
  include Roar::JSON

  property :title
  collection :songs, extend: SongRepresenter, class: Song
end
```

Both `::property` and `::collection` accept options for nesting representers into representers.

The `extend:` option tells Roar which representer to use for the nested objects (here, the array items of the `album.songs` field). When parsing a document `class:` defines the nested object type.

Consider the following object setup.

```ruby
album = Album.new(title: "True North")
album.songs << Song.new(title: "The Island")
album.songs << Song.new(title: "Changing Tide")
```

You apply the `AlbumRepresenter` and you get a nested document.

```ruby
AlbumRepresenter.new(album).to_json #=> {"title":"True North","songs":[{"title":"The Island"},{"title":"Changing Tide"}]}
```

This works vice-versa.

```ruby
album = Album.new

AlbumRepresenter.new(album).from_json('{"title":"Indestructible","songs":[{"title":"Tropical London"},{"title":"Roadblock"}]}')

puts album.songs[1] #=> #<Song title="Roadblock">
```

The nesting of two representers can map composed object as you find them in many many APIs.

In case you're after virtual nesting, where a nested block in your document still maps to the same outer object, [check out the `::nested` method](https://github.com/trailblazer/representable#document-nesting).

## Inline Representer

Sometimes you don't wanna create two separate representers - although it makes them reusable across your app. Use inline representers if you're not intending this.

```ruby
class AlbumRepresenter < Roar::Decorator
  include Roar::JSON

  property :title

  collection :songs, class: Song do
    property :title
  end
end
```

This will give you the same rendering and parsing behaviour as in the previous example with just one module.


## Syncing Objects

Usually, when parsing, nested objects are created from scratch. If you want nested objects to be updated instead of being newly created, use `parse_strategy:`.

```ruby
class AlbumRepresenter < Roar::Decorator
  include Roar::JSON

  property :title

  collection :songs, extend: SongRepresenter, parse_strategy: :sync
end
```

This will advise Roar to update existing `songs`.

```ruby
album.songs[0].object_id #=> 81431220

AlbumRepresenter.new(album).from_json('{"title":"True North","songs":[{"title":"Secret Society"},{"title":"Changing Tide"}]}')

album.songs[0].title #=> Secret Society
album.songs[0].object_id #=> 81431220
```
Roar didn't create a new `Song` instance but updated its attributes, only.

We're currently [working on](https://github.com/trailblazer/roar/issues/85) better strategies to easily implement `POST` and `PUT` semantics in your APIs without having to worry about the nitty-gritties.


## Coercion

Roar provides coercion with the [virtus](https://github.com/solnic/virtus) gem.

```ruby
require 'roar/coercion'
require 'roar/json'

class SongRepresenter < Roar::Decorator
  include Roar::JSON
  include Roar::Coercion

  property :title
  property :released_at, type: DateTime
end
```

The `:type` option allows to set a virtus-compatible type.

```ruby
song = Song.new

SongRepresenter.new(song).from_json('{"released_at":"1981/03/31"}')

song.released_at #=> 1981-03-31T00:00:00+00:00
```


## More Features

Roar/representable gives you many more mapping features like renaming attributes, wrapping, passing options, etc. See the [representable documentation](http://trailblazer.to/gems/representable/3.0/api.html) for a detailed explanation.


## Hypermedia

Roar comes with built-in support for embedding and processing hypermedia in your documents.

```ruby
class SongRepresenter < Roar::Decorator
  include Roar::JSON
  include Roar::Hypermedia

  property :title

  link :self do
    "http://songs/#{title}"
  end
end
```

The `Hypermedia` feature allows declaring links using the `::link` method. In the block, you have access to the represented model. When using representer modules, the block is executed in the model's context.

However, when using decorators, the context is the decorator instance, allowing you to access additional data. Use `represented` to retrieve model data.

```ruby
class SongRepresenter < Roar::Decorator
  # ..
  link :self do
    "http://songs/#{represented.title}"
  end
end
```

This will render links into your representation.

```ruby
SongRepresenter.new(song).to_json #=> {"title":"Roxanne","links":[{"rel":"self","href":"http://songs/Roxanne"}]}
```

Per default, links are pushed into the hash using the `links` key. Link blocks are executed in represented context, allowing you to call any instance method of your model (here, we call `#title`).

Also, note that [roar-rails](https://github.com/apotonick/roar-rails) allows using URL helpers in link blocks.


## Passing Options

Sometimes you need more data in the link block. Data that's not available from the represented model.

```ruby
class SongRepresenter < Roar::Decorator
  include Roar::JSON

  property :title

  link :self do |opts|
    "http://#{opts[:base_url]}songs/#{title}"
  end
end
```

Pass this data to the rendering method.

```ruby
representer = SongRepresenter.new(song)
representer.to_json(base_url: "localhost:3001/")
```

Any options passed to `#to_json` will be available as block arguments in the link blocks.


## Specify Decorator

If you have a property that is a separate class or model, you can specify a decorator for that property. Suppose there is a separate `Artist` model for an album. When the album is eagerly loaded, the artist model could be represented along with it.

```ruby
class ArtistRepresenter < Roar::Decorator
  property :name
end

class AlbumRepresenter < Roar::Decorator
  # ..
  property :artist, decorator: ArtistRepresenter
end
```

## Consuming Hypermedia

Since we defined hypermedia attributes in the representer we can also consume this hypermedia when we parse documents.

```ruby
representer.from_json('{"title":"Roxanne","links":[{"rel":"self","href":"http://songs/Roxanne"}]}')

representer.links[:self].href #=> "http://songs/Roxanne"
```

Reading link attributes works by using `#links[]` on the consuming instance.

This allows an easy way to discover hypermedia and build navigational logic on top.


## Media Formats

While Roar comes with a built-in hypermedia format, there's official media types that are widely recognized. Roar currently supports HAL and JSON API.

Simply by including a module you make your representer understand the media type. This makes it easy to change formats during evaluation.

## HAL-JSON

The [HAL](http://stateless.co/hal_specification.html) format is a simple media type that defines embedded resources and hypermedia.

```ruby
require 'roar/json/hal'

class SongRepresenter < Roar::Decorator
  include Roar::JSON::HAL

  property :title

  link :self do
    "http://songs/#{title}"
  end
end
```

Documentation for HAL can be found in the [API docs](http://rdoc.info/github/trailblazer/roar/Roar/JSON/HAL).

Make sure you [understand the different contexts](#hypermedia) for links when using decorators.

### Hypermedia

Including the `Roar::JSON::HAL` module adds some more DSL methods to your module. It still allows using `::link` but treats them slightly different.

```ruby
representer.to_json
#=> {"title":"Roxanne","_links":{"self":{"href":"http://songs/Roxanne"}}}
```

According to the HAL specification, links are now key with their `rel` attribute under the `_links` key.

Parsing works like-wise: Roar will use the same setters as before but it knows how to read HAL.

### Nesting

Nested, or embedded, resources can be defined using the `:embedded` option.

```ruby
class AlbumRepresenter < Roar::Decorator
  include Roar::JSON::HAL

  property :title

  collection :songs, class: Song, embedded: true do
    property :title
  end
end
```

To embed a resource, you can use an inline representer or use `:extend` to specify the representer name.

```ruby
AlbumRepresenter.new(album).to_json

#=> {"title":"True North","_embedded":{"songs":[{"title":"The Island"},{"title":"Changing Tide"}]}}
```

HAL keys nested resources under the `_embedded` key and then by their type.

All HAL features in Roar are discussed in the [API docs](http://rdoc.info/github/trailblazer/roar/Roar/JSON/HAL), including [array links](https://github.com/trailblazer/roar/blob/master/lib/roar/json/hal.rb#L196).

## JSON API

Roar also supports [JSON API](http://jsonapi.org/) via the [Roar JSON API gem](https://github.com/trailblazer/roar-jsonapi).

## Client-Side Support

Being a bi-directional mapper that does rendering _and_ parsing, Roar representers are perfectly suitable for use in clients, too. In many projects, representers are shared as gems between server and client.

Consider the following shared representer.

```ruby
class SongRepresenter < Roar::Decorator
  include Roar::JSON
  include Roar::Hypermedia

  property :title
  property :id

  link :self do
    "http://songs/#{title}"
  end
end
```

In a client where you don't have access to the database it is common to use `OpenStruct` classes as domain objects.

```ruby
require 'roar/client'
require 'roar/json'

class Song < OpenStruct
  include Roar::JSON
  include SongRepresenter
  include Roar::Client
end
```

## HTTP Support

The `Client` module mixes all necessary methods into the client class, e.g. it provides HTTP support

```ruby
song = Song.new(title: "Roxanne")
song.post(uri: "http://localhost:4567/songs", as: "application/json")

song.id #=> 42
```

What happens here?

* You're responsible for initializing the client object with attributes. This can happen with in the constructor or using accessors.
* `post` will use the included `SongRepresenter` to compile the document using `#to_json`.
* The document gets `POST`ed to the passed URL.
* If a document is returned, it is deserialized and the client's attributes are updated.

This is a very simple but efficient mechanism for working with representations in a client application.

Roar works with all HTTP request types, check out `GET`.

```ruby
song = Client::Song.new
song.get(uri: "http://localhost:4567/songs/1", as: "application/json")

song.title #=> "Roxanne"
song.links[:self].href #=> http://localhost/songs/1
```

As `GET` is not supposed to send any data, you can use `#get` on an empty object to populate it with the server data.

### HTTPS

Roar supports SSL connections - they are automatically detected via the protocol.

```ruby
song.get(uri: "https://localhost:4567/songs/1")
```

### Basic Authentication

The HTTP verbs allow you to specify credentials for HTTP basic auth.

```ruby
song.get(uri: "http://localhost:4567/songs/1", basic_auth: ["username", "secret_password"])

```

### Client SSL certificates

(Only currently supported with Net:Http)

```ruby
song.get(uri: "http://localhost:4567/songs/1", pem_file: "/path/to/client/cert.pem", ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER)

```

Note: ssl_verify_mode is not required and will default to ```OpenSSL::SSL::VERIFY_PEER)```



### Request customization

All verbs yield the request object before the request is sent, allowing to modify it. It is a `Net::HTTP::Request` instance (unless you use Faraday).

 ```ruby
song.get(uri: "http://localhost:4567/songs/1") do |req|
  req.add_field("Cookie", "Yumyum")
end
```

### Error handling

In case of a non-2xx response status, `#get` and friends raise a `Roar::Transport::Error` exception. The original response can be accessed as follows.

```ruby
  song.get(uri: "http://localhost/songs1") # not-existing.
rescue Roar::Transport::Error => exception
  exception.response.code #=> 404
```

## XML

Roar also comes with XML support.

```ruby
class SongRepresenter < Roar::Decorator
  include Roar::XML
  include Roar::Hypermedia

  property :title
  property :id

  link :self do
    "http://songs/#{title}"
  end
end
```

Include the `Roar::XML` engine and get bi-directional XML for your objects.

```ruby
song = Song.new(title: "Roxanne", id: 42)

SongRepresenter.new(song).to_xml
```

Note that you now use `#to_xml` and `#from_xml`.

```xml
<song>
  <title>Roxanne</title>
  <id>42</id>
  <link rel="self" href="http://songs/Roxanne"/>
</song>
```

Please consult the [representable XML documentation](https://github.com/trailblazer/representable/#more-on-xml) for all its great features.


## Support

Questions? Need help? Free 1st Level Support on irc.freenode.org#roar !
We also have a [mailing list](https://groups.google.com/forum/?fromgroups#!forum/roar-talk), yiha!

## License

Roar is released under the [MIT License](http://www.opensource.org/licenses/MIT).
