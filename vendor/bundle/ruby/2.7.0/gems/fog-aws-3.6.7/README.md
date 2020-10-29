# Fog::Aws

![Gem Version](https://badge.fury.io/rb/fog-aws.svg)
[![Build Status](https://travis-ci.org/fog/fog-aws.svg?branch=master)](https://travis-ci.org/fog/fog-aws)
[![Test Coverage](https://codeclimate.com/github/fog/fog-aws/badges/coverage.svg)](https://codeclimate.com/github/fog/fog-aws)
[![Code Climate](https://codeclimate.com/github/fog/fog-aws.svg)](https://codeclimate.com/github/fog/fog-aws)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fog-aws'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fog-aws

## Usage

Before you can use fog-aws, you must require it in your application:

```ruby
require 'fog/aws'
```

Since it's a bad practice to have your credentials in source code, you should load them from default fog configuration file: ```~/.fog```. This file could look like this:

```
default:
  aws_access_key_id:     <YOUR_ACCESS_KEY_ID>
  aws_secret_access_key: <YOUR_SECRET_ACCESS_KEY>
```

### EC2

#### Connecting to the EC2 Service:

```ruby
ec2 = Fog::Compute.new :provider => 'AWS', :region => 'us-west-2'
```

You can review all the requests available with this service using ```#requests``` method:

```ruby
ec2.requests # => [:allocate_address, :assign_private_ip_addresses, :associate_address, ...]
```

#### Launch an EC2 on-demand instance:

```ruby
response = ec2.run_instances(
  "ami-23ebb513",
  1,
  1,
  "InstanceType"  => "t1.micro",
  "SecurityGroup" => "ssh",
  "KeyName"       => "miguel"
)
instance_id = response.body["instancesSet"].first["instanceId"] # => "i-02db5af4"
instance = ec2.servers.get(instance_id)
instance.wait_for { ready? }
puts instance.public_ip_address # => "356.300.501.20"
```

#### Terminate an EC2 instance:

```ruby
instance = ec2.servers.get("i-02db5af4")
instance.destroy
```

`Fog::AWS` is more than EC2 since it supports many services provided by AWS. The best way to learn and to know about how many services are supported is to take a look at the source code. To review the tests directory and to play with the library in ```bin/console``` can be very helpful resources as well.

### S3

#### Connecting to the S3 Service:

```ruby
s3 = Fog::Storage.new(provider: 'AWS', region: 'eu-central-1')
```

#### Creating a file:

```ruby
directory = s3.directories.new(key: 'gaudi-portal-dev')
file = directory.files.create(key: 'user/1/Gemfile', body: File.open('Gemfile'), tags: 'Org-Id=1&Service-Name=My-Service')
```

#### Listing files:

```ruby
directory = s3.directories.get('gaudi-portal-dev', prefix: 'user/1/')
directory.files
```

#### Generating a URL for a file:

```ruby
directory.files.new(key: 'user/1/Gemfile').url(Time.now + 60)
```

## Documentation

See the [online documentation](http://www.rubydoc.info/github/fog/fog-aws) for a complete API reference.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/fog/fog-aws/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
