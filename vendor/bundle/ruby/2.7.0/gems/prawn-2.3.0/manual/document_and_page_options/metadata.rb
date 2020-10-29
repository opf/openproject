# frozen_string_literal: true

# To set the document metadata just pass a hash to the <code>:info</code>
# option when creating new documents.
# The keys in the example below are arbitrary, so you may add whatever keys you
# want.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')

info = {
  Title: 'My title',
  Author: 'John Doe',
  Subject: 'My Subject',
  Keywords: 'test metadata ruby pdf dry',
  Creator: 'ACME Soft App',
  Producer: 'Prawn',
  CreationDate: Time.now
}

Prawn::Document.generate(filename, info: info) do
  text 'This is a test of setting metadata properties via the info option.'
  text 'While the keys are arbitrary, the above example sets common attributes.'
end
