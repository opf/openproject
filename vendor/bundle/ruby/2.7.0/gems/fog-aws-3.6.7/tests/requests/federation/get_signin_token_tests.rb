Shindo.tests('AWS::Federation | signin tokens', ['aws']) do
  @signin_token_format = {
    'SigninToken' => String
  }

  tests("#get_signin_token").formats(@signin_token_format) do
    pending unless Fog.mocking?

    Fog::AWS[:federation].get_signin_token("test_policy")
  end
end
