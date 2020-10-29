Shindo.tests('AWS::STS | session tokens', ['aws']) do

	@session_format = {
		'SessionToken' => String,
		'SecretAccessKey' => String,
		'Expiration' => String,
		'AccessKeyId' => String,
		'RequestId'	=> String
	}

	tests("#get_session_token").formats(@session_format) do
		pending if Fog.mocking?
		Fog::AWS[:sts].get_session_token.body
	end

end
