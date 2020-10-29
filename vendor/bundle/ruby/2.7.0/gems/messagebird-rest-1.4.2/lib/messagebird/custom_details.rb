require 'messagebird/base'

module MessageBird
  class CustomDetails < MessageBird::Base
    # CustomDetails holds free-input fields for the Contact object.
    attr_accessor :custom1, :custom2, :custom3, :custom4
  end
end
