# ActiveModel::Serializers::Xml

This gem provides XML serialization for your Active Model objects and Active Record models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activemodel-serializers-xml'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activemodel-serializers-xml

## Usage

### ActiveModel::Serializers::Xml

To use the `ActiveModel::Serializers::Xml` you only need to change from
`ActiveModel::Serialization` to `ActiveModel::Serializers::Xml`.

```ruby
class Person
  include ActiveModel::Serializers::Xml

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

With the `to_xml` you have an XML representing the model.

```ruby
person = Person.new
person.to_xml # => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<person>\n  <name nil=\"true\"/>\n</person>\n"
person.name = "Bob"
person.to_xml # => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<person>\n  <name>Bob</name>\n</person>\n"
```

From an XML string you define the attributes of the model.
You need to have the `attributes=` method defined on your class:

```ruby
class Person
  include ActiveModel::Serializers::Xml

  attr_accessor :name

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    {'name' => nil}
  end
end
```

Now it is possible to create an instance of person and set the attributes using `from_xml`.

```ruby
xml = { name: 'Bob' }.to_xml
person = Person.new
person.from_xml(xml) # => #<Person:0x00000100c773f0 @name="Bob">
person.name          # => "Bob"
```

### ActiveRecord::XmlSerializer

This gem also provides serialization to XML for Active Record.

Please see ActiveRecord::Serialization#to_xml for more information.

## Contributing to ActiveModel::Serializers::Xml

ActiveModel::Serializers::Xml is work of many contributors. You're encouraged to submit pull requests, propose features and discuss issues.

See [CONTRIBUTING](CONTRIBUTING.md)
