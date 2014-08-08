module OpenIDConnectSpecHelpers
  def redirect_from_provider
    # Emulate the provider's redirect with a nonsense code.
    get "/auth/#{provider.class.provider_name}/callback",
      :code => "foobar",
      :redirect_uri => "http://localhost:3000/auth/#{provider.class.provider_name}/callack"
  end

  def click_on_signin(pro_name = provider.class.provider_name)
    # Emulate click on sign-in for that particular provider
    get "/auth/#{pro_name}"
  end
end
