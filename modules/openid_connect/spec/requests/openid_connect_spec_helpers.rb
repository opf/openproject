module OpenIDConnectSpecHelpers
  def redirect_from_provider(name = 'heroku')
    # Emulate the provider's redirect with a nonsense code.
    get "/auth/#{name}/callback",
        params: {
          code: 'foobar',
          redirect_uri: "http://localhost:3000/auth/#{name}/callback",
          state: session['omniauth.state']
        }
  end

  def click_on_signin(pro_name = 'heroku')
    # Emulate click on sign-in for that particular provider
    get "/auth/#{pro_name}"
  end
end
