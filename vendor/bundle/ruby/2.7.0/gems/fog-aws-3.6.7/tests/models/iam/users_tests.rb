Shindo.tests("Fog::Compute[:iam] | users", ['aws','iam']) do

  iam = Fog::AWS[:iam]

  user_one_name   = 'fake_user_one'
  user_two_name   = 'fake_user_two'
  user_three_name = 'fake_user_three'
  user_three_path = '/path/to/fake_user_three/'
  user_four_name  = 'fake_user_four'

  def all_users
    Fog::AWS[:iam].users.all.select{|user| user.id =~ /^fake_user/ }
  end

  tests('#create').succeeds do
    user_one = iam.users.create(:id => user_one_name)
    user_one.id == user_one_name
  end

  tests('#all','there is only one user').succeeds do
    all_users.size == 1
  end

  tests('#all','the only user should match').succeeds do
    all_users.first.id == user_one_name
  end

  tests('#create','a second user').succeeds do
    user_two = iam.users.create(:id => user_two_name)
    user_two.id == user_two_name
  end

  tests('#all','there are two users').succeeds do
    all_users.size == 2
  end

  user = iam.users.get(user_one_name)

  tests('#get','an existing user').succeeds do
    user.id == user_one_name
  end

  tests('#current').succeeds do
    iam.users.current
  end

  tests('#get',"returns nil if the user doesn't exists").succeeds do
    iam.users.get('non-exists') == nil
  end

  tests('#policies','it has no policies').succeeds do
    user.policies.empty?
  end

  tests('#access_keys','it has no keys').succeeds do
    user.access_keys.empty?
  end

  # test that users create in mock and be signed in via access key and share data
  if Fog.mocking?
    tests("mocking access key usage") do
      access_key = user.access_keys.create

      user_client = Fog::AWS::IAM.new(
        :aws_access_key_id     => access_key.identity,
        :aws_secret_access_key => access_key.secret_access_key
      )

      tests("sets correct data").succeeds do
        user_client.users.size > 1
      end

      tests("set current user name").succeeds do
        user_client.current_user_name == user.identity
      end
    end
  end

  tests('#password=nil', 'without a password').succeeds do
    user.password = nil
    user.password_created_at.nil?
  end

  tests('#password=(password)').succeeds do
    user.password = SecureRandom.base64(10)

    user.password_created_at.is_a?(Time)
  end

  tests('#password=(update_password)').succeeds do
    user.password = SecureRandom.base64(10)

    user.password_created_at.is_a?(Time)
  end

  tests('#password=nil', 'with a password').succeeds do
    user.password = nil
    user.password_created_at.nil?
  end

  tests('#create', 'assigns path').succeeds do
    user_three = iam.users.create(:id => user_three_name, :path => user_three_path)
    user_three.path == user_three_path
  end

  tests('#create', 'defaults path to /').succeeds do
    user_four = iam.users.create(:id => user_four_name)
    user_four.path == '/'
  end

  tests('#destroy','an existing user').succeeds do
    iam.users.get(user_one_name).destroy
  end

  tests('#destroy','clean up remaining user').succeeds do
    iam.users.get(user_two_name).destroy
  end

end
