module OAuthConnectionsHelpers
  def mock_one_drive_authorization_validation(with: {})
    me_response = {
      businessPhones: [
        "+45 123 4567 8901"
      ],
      displayName: "Sheev Palpatine ",
      givenName: "Sheev",
      jobTitle: "Galactic Senator",
      mail: "palpatine@senate.com",
      mobilePhone: "+45 123 4567 8901",
      officeLocation: "500 Republica",
      preferredLanguage: "en-US",
      surname: "Palpatine",
      userPrincipalName: "palpatine@senate.com",
      id: "87d349ed-44d7-43e1-9a83-5f2406dee5bd"
    }.to_json

    stub = stub_request(:get, "https://graph.microsoft.com/v1.0/me")
      .to_return(status: 200, body: me_response, headers: { "Content-Type" => "application/json" })

    if with.present?
      stub.with(with)
    end
  end
end

RSpec.configure do |c|
  c.include OAuthConnectionsHelpers, :oauth_connection_helpers
end
