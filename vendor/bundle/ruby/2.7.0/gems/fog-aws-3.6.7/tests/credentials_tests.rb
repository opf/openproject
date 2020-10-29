# frozen_string_literal: true

Shindo.tests('AWS | credentials', ['aws']) do
  old_mock_value = Excon.defaults[:mock]
  fog_was_mocked = Fog.mocking?
  Excon.stubs.clear
  Fog.unmock!
  begin
    Excon.defaults[:mock] = true
    Excon.stub({ method: :put, path: '/latest/api/token' }, { status: 200, body: 'token1234' })

    Excon.stub({ method: :get, path: '/latest/meta-data/iam/security-credentials/' }, { status: 200, body: 'arole' })
    Excon.stub({ method: :get, path: '/latest/meta-data/placement/availability-zone/' }, { status: 200, body: 'us-west-1a' })

    expires_at = Time.at(Time.now.to_i + 500)
    credentials = {
      'AccessKeyId' => 'dummykey',
      'SecretAccessKey' => 'dummysecret',
      'Token' => 'dummytoken',
      'Expiration' => expires_at.xmlschema
    }

    Excon.stub({ method: :get, path: '/latest/meta-data/iam/security-credentials/arole' }, { status: 200, body: Fog::JSON.encode(credentials) })

    tests('#fetch_credentials') do
      returns(aws_access_key_id: 'dummykey',
              aws_secret_access_key: 'dummysecret',
              aws_session_token: 'dummytoken',
              region: 'us-west-1',
              aws_credentials_expire_at: expires_at) { Fog::AWS::Compute.fetch_credentials(use_iam_profile: true) }
    end

    tests('#fetch_credentials when the v2 token 404s') do
      Excon.stub({ method: :put, path: '/latest/api/token' }, { status: 404, body: 'not found' })
      returns(aws_access_key_id: 'dummykey',
              aws_secret_access_key: 'dummysecret',
              aws_session_token: 'dummytoken',
              region: 'us-west-1',
              aws_credentials_expire_at: expires_at) { Fog::AWS::Compute.fetch_credentials(use_iam_profile: true) }
    end

    tests('#fetch_credentials when the v2 disabled') do
      returns(aws_access_key_id: 'dummykey',
              aws_secret_access_key: 'dummysecret',
              aws_session_token: 'dummytoken',
              region: 'us-west-1',
              aws_credentials_expire_at: expires_at) { Fog::AWS::Compute.fetch_credentials(use_iam_profile: true, disable_imds_v2: true) }
    end

    ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] = '/v1/credentials?id=task_id'
    Excon.stub({ method: :get, path: '/v1/credentials?id=task_id' }, { status: 200, body: Fog::JSON.encode(credentials) })

    tests('#fetch_credentials') do
      returns(aws_access_key_id: 'dummykey',
              aws_secret_access_key: 'dummysecret',
              aws_session_token: 'dummytoken',
              region: 'us-west-1',
              aws_credentials_expire_at: expires_at) { Fog::AWS::Compute.fetch_credentials(use_iam_profile: true) }
    end

    ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] = nil

    compute = Fog::AWS::Compute.new(use_iam_profile: true)

    tests('#refresh_credentials_if_expired') do
      returns(nil) { compute.refresh_credentials_if_expired }
    end

    credentials['AccessKeyId'] = 'newkey'
    credentials['SecretAccessKey'] = 'newsecret'
    credentials['Expiration'] = (expires_at + 10).xmlschema

    Excon.stub({ method: :get, path: '/latest/meta-data/iam/security-credentials/arole' }, { status: 200, body: Fog::JSON.encode(credentials) })

    Fog::Time.now = expires_at + 1
    tests('#refresh_credentials_if_expired') do
      returns(true) { compute.refresh_credentials_if_expired }
      returns('newkey') { compute.instance_variable_get(:@aws_access_key_id) }
    end
    Fog::Time.now = Time.now

    default_credentials = Fog::AWS::Compute.fetch_credentials({})
    tests('#fetch_credentials when the url 404s') do
      Excon.stub({ method: :put, path: '/latest/api/token' }, { status: 404, body: 'not found' })
      Excon.stub({ method: :get, path: '/latest/meta-data/iam/security-credentials/' }, { status: 404, body: 'not bound' })
      Excon.stub({ method: :get, path: '/latest/meta-data/placement/availability-zone/' }, { status: 400, body: 'not found' })
      returns(default_credentials) { Fog::AWS::Compute.fetch_credentials(use_iam_profile: true) }
    end

    mocked_credentials = {
      aws_access_key_id: 'access-key-id',
      aws_secret_access_key: 'secret-access-key',
      aws_session_token: 'session-token',
      aws_credentials_expire_at: Time.at(Time.now.to_i + 500).xmlschema
    }
    tests('#fetch_credentials when mocking') do
      Fog.mock!
      Fog::AWS::Compute::Mock.data[:iam_role_based_creds] = mocked_credentials
      returns(mocked_credentials) { Fog::AWS::Compute.fetch_credentials(use_iam_profile: true) }
    end
  ensure
    ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] = nil
    Excon.stubs.clear
    Excon.defaults[:mock] = old_mock_value
    Fog.mock! if fog_was_mocked
  end
end
