Shindo.tests('AWS::SES | verified email address requests', ['aws', 'ses']) do

  tests('success') do

    tests("#verify_email_address('test@example.com')").formats(AWS::SES::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:ses].verify_email_address('test@example.com').body
    end

    tests("#list_verified_email_addresses").formats(AWS::SES::Formats::BASIC.merge('VerifiedEmailAddresses' => [String])) do
      pending if Fog.mocking?
      Fog::AWS[:ses].list_verified_email_addresses.body
    end

    # email won't be there to delete, but succeeds regardless
    tests("#delete_verified_email_address('test@example.com')").formats(AWS::SES::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:ses].delete_verified_email_address('notaanemail@example.com').body
    end

  end

  tests('failure') do

  end

end
