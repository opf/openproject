# ValidateEmail

This gem adds the capability of validating email addresses to `ActiveModel`. 
The gem only supports Rails 3 (has dependencies in ActiveModel and ActiveSupport 3.0)

### Installation
    # add this to your Gemfile
    gem "validate_email"

    # and then run
    rake gems:install

    # or just run
    sudo gem install validate_email

### Usage

#### With ActiveRecord
    class Pony < ActiveRecord::Base
      # standard validation
      validates :email_address, :email => true

      # with allow_nil
      validates :email_address, :email => {:allow_nil => true}

      # with allow_blank
      validates :email_address, :email => {:allow_blank => true}
    end

#### With ActiveModel
    class Unicorn
      include ActiveModel::Validations

      attr_accessor :email_address

      # with legacy syntax (the syntax above works also)
      validates_email :email_address, :allow_blank => true
    end

#### I18n

The error message will be looked up according to the standard ActiveModel::Errors scheme.
For the above Unicorn class this would be:

 * activemodel.errors.models.unicorn.attributes.email_address.email
 * activemodel.errors.models.unicorn.email
 * activemodel.errors.messages.email
 * errors.attributes.email_address.email
 * errors.messages.email

A default errors.messages.email of `is not a valid email address` is provided.
You can also pass the `:message => "my custom error"` option to your validation to define your own custom message.

## Authors

**Tanel Suurhans** (<http://twitter.com/tanelsuurhans>)  
**Tarmo Lehtpuu** (<http://twitter.com/tarmolehtpuu>)

## License
Copyright 2010 by PerfectLine LLC (<http://www.perfectline.co.uk>) and is released under the MIT license.
