actionpack-xml\_parser
======================

A XML parameters parser for Action Pack (removed from core in Rails 4.0)

Installation
------------

Include this gem into your Gemfile:

```ruby
gem 'actionpack-xml_parser'
```

Parameters parsing rules
------------------------

The parameters parsing is handled by `ActiveSupport::XMLConverter` so there may
be specific features and subtle differences depending on the chosen XML backend.

### Hashes

Basically, each node represents a key. With the following XML:

```xml
<person><name>David</name></person>
```

The resulting parameters will be:

```ruby
{"person" => {"name" => "David"}}
```

### File attachment

You can specify the `type` attribute of a node to attach files:

```xml
<person>
  <avatar type="file" name="me.jpg" content_type="image/jpg"><!-- File content --></avatar>
</person>
```

The resulting parameters will include a `StringIO` object with the given content,
name and content type set accordingly:

```ruby
{"person" => {"avatar" => #<StringIO:...>}}
```

### Arrays

There are several ways to pass an array. You can either specify multiple nodes
with the same name:

```xml
<person>
  <address city="Chicago"/>
  <address city="Ottawa"/>
</person>
```

The resulting parameters will be:

```ruby
{"person" => {"address" => [{"city" => "Chicago"}, {"city" => "Ottawa"}]}}
```

You can also specify the `type` attribute of a node and nest child nodes inside:

```xml
<person>
  <addresses type="array">
    <address city="Melbourne"/>
    <address city="Paris"/>
  </addresses>
</person>
```

will result in:

```ruby
{"person" => {"addresses" => [{"city" => "Melbourne"}, {"city" => "Paris"}]}}
```
