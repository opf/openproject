# frozen_string_literal: true

# Examples for document encryption.

require_relative '../example_helper'

Prawn::ManualBuilder::Example.generate('security.pdf', page_size: 'FOLIO') do
  package 'security' do |p|
    p.example 'encryption',  eval_source: false, full_source: true
    p.example 'permissions', eval_source: false, full_source: true

    p.intro do
      prose <<-TEXT
        Security lets you control who can read the document by defining
        a password.

        The examples include:
      TEXT

      list(
        'How to encrypt the document without the need for a password',
        'How to configure the regular user permissions',
        'How to require a password for the regular user',
        'How to set a owner password that bypass the document permissions'
      )
    end
  end
end
