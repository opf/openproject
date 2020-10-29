MessageBird's REST API for Ruby
===============================
This repository contains the open source Ruby client for MessageBird's REST API. Documentation can be found at: https://developers.messagebird.com/

[![Build Status](https://travis-ci.org/messagebird/ruby-rest-api.svg?branch=master)](https://travis-ci.org/messagebird/ruby-rest-api)

Requirements
------------
- [Sign up](https://dashboard.messagebird.com/app/en/sign-up) for a free MessageBird account
- Create a new `access_key` in the developers sections
- MessageBird's API client for Ruby requires Ruby >= 1.9

Installation
------------
You can either include the following line in your Gemfile:

```ruby
gem 'messagebird-rest', :require => 'messagebird'
```

Or you can just manually install it from the command line:
```sh
$ gem install messagebird-rest
```

Examples
--------
We have put some self-explanatory examples in the *examples* directory, but here is a quick breakdown on how it works. First, you need to create an instance of **MessageBird::Client**. Be sure to replace **YOUR_ACCESS_KEY** with something real in the bottom example.

```ruby
require 'pp'              # Only needed for this example
require 'messagebird'

client = MessageBird::Client.new(YOUR_ACCESS_KEY)
```

That's easy enough. Now we can query the server for information.

##### Balance
Lets start with out with an overview of our balance.

```ruby
pp client.balance

#<MessageBird::Balance:0x007f8d5c83f478
 @amount=9,
 @payment="prepaid",
 @type="credits">
```

##### Messages
Chances are that the most common use you'll have for this API client is the ability to send out text messages. For that purpose we have created the **message_create** method, which takes the required *originator*, one or more *recipients* and a *body* text for parameters.

Optional parameters can be specified as a hash.

```ruby
pp client.message_create('FromMe', '31612345678', 'Hello World', :reference => 'MyReference')

#<MessageBird::Message:0x007f8d5b883520
 @body="Hello World",
 @createdDatetime=2014-07-07 12:20:30 +0200,
 @datacoding="plain",
 @direction="mt",
 @gateway=239,
 @href=
  "https://rest.messagebird.com/messages/211e6280453ba746e8eeff7b12582146",
 @id="211e6280453ba746e8eeff7b12582146",
 @mclass=1,
 @originator="FromMe",
 @recipient=
  {"totalCount"=>1,
   "totalSentCount"=>1,
   "totalDeliveredCount"=>0,
   "totalDeliveryFailedCount"=>0,
   "items"=>
    [#<MessageBird::Recipient:0x007f8d5c058c00
      @recipient=31612345678,
      @status="sent",
      @statusDatetime=2014-07-07 12:20:30 +0200>]},
 @reference="MyReference",
 @scheduledDatetime=nil,
 @type="sms",
 @typeDetails={},
 @validity=nil>
```

As a possible follow-up, you can use the **message** method with the above mentioned batch-id to query the status of the message that you just created. It will return a similar Message object.

```ruby
client.message('211e6280453ba746e8eeff7b12582146')
```

##### HLR
To perform HLR lookups we have created the **hlr_create** method, which takes a number and a reference for parameters.

```ruby
pp client.hlr_create('31612345678', 'MyReference')

#<MessageBird::HLR:0x007f8d5b8dafc8
 @createdDatetime=2014-07-07 12:20:05 +0200,
 @href="https://rest.messagebird.com/hlr/4933bed0453ba7455031712h16830892",
 @id="4933bed0453ba7455031712h16830892",
 @msisdn=31612345678,
 @network=nil,
 @reference="MyReference",
 @status="sent",
 @statusDatetime=2014-07-07 12:20:05 +0200>
```

Similar to the **message_create** and **message** methods, the **hlr_create** method has an accompanying **hlr** method to poll the HLR object.

```ruby
client.hlr('4933bed0453ba7455031712h16830892')
```

##### Verify (One-Time Password)
You can send and verify One-Time Passwords through the MessageBird API using the **verify_create** and **verify_token** methods.

```ruby
# verify_create requires a recipient as a required parameter, and other optional paramaters
client.verify_create(31612345678, {:reference => "YourReference"})

#<MessageBird::Verify:0x007fb3c18c8148
 @id="080b7f804555213678f14f6o24607735",
 @recipient="31612345678",
 @reference="YourReference",
 @status="sent",
 @href={"message"=>"https://rest.messagebird.com/messages/67d42f004555213679416f0b13254392"},
 @createdDatetime=2015-05-12 16:51:19 +0200,
 @validUntilDatetime=2015-05-12 16:51:49 +0200>
```

This sends a token to the recipient, which can be verified with the **verify_token** method.

```ruby
# verify_token requires the id of the verify request and a token as required parameters.
client.verify_token('080b7f804555213678f14f6o24607735', 123456)
```

##### Voice Message
MessageBird also offers the ability to send out a text message as a voice message, or text-to-speech. For that purpose we have created the **voice_message_create** method, which takes one or more required *recipients* and a *body* text for parameters.

Optional parameters can be specified as a hash.

```ruby
pp client.voice_message_create('31612345678', 'Hello World', :reference => 'MyReference')

#<MessageBird::VoiceMessage:0x000001030101b8
 @body="Hello World",
 @createdDatetime=2014-07-09 12:17:50 +0200,
 @href=
  "https://rest.messagebird.com/voicemessages/a08e51a0353bd16cea7f298a37405850",
 @id="a08e51a0353bd16cea7f298a37405850",
 @ifMachine="continue",
 @language="en-gb",
 @recipients=
  {"totalCount"=>1,
   "totalSentCount"=>1,
   "totalDeliveredCount"=>0,
   "totalDeliveryFailedCount"=>0,
   "items"=>
    [#<MessageBird::Recipient:0x000001011d3178
      @recipient=31612345678,
      @status="calling",
      @statusDatetime=2014-07-09 12:17:50 +0200>]},
 @reference="MyReference",
 @repeat=1,
 @scheduledDatetime=nil,
 @voice="female">
```

Similar to regular messaging and HLR lookups, there is a method available to fetch the VoiceMessage object by using an *id*.

```ruby
client.voice_message('a08e51a0353bd16cea7f298a37405850')
```

Documentation
-------------
Complete documentation, instructions, and examples are available at:
[https://developers.messagebird.com/](https://developers.messagebird.com/).

License
-------
The MessageBird REST Client for Ruby is licensed under [The BSD 2-Clause License](http://opensource.org/licenses/BSD-2-Clause). Copyright (c) 2014, MessageBird
