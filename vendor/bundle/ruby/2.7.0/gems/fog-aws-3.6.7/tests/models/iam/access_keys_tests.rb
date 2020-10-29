Shindo.tests("Fog::Compute[:iam] | access_keys", ['aws','iam']) do

  iam = Fog::AWS[:iam]

  @username = 'fake_user'
  @user = iam.users.create(:id => @username)


  tests('#all', 'there are no access keys for a new user').succeeds do
    @user.access_keys.empty?
  end


  tests('#create','an access key').succeeds do
    access_key = @user.access_keys.create
    access_key.id =~ /[A-Z0-9]{20}/
    access_key.secret_access_key =~ /[\S]{40}/
    access_key.status == "Active"
    access_key.username == @username
    @access_key_id = access_key.id
  end

  @user.access_keys.create

  tests('#all','there are two access keys').succeeds do
    @user.access_keys.size == 2
  end

  tests('#get') do
    tests('a valid access key id').succeeds do
      access_key = @user.access_keys.get(@access_key_id)
      access_key.id == @access_key_id
      access_key.secret_access_key == nil
      access_key.status == "Active"
      access_key.username == @username
    end

    tests('an invalid access key').succeeds do
      @user.access_keys.get('non-existing') == nil
    end
  end

  tests('#destroy', 'decrease by one the number of access keys').succeeds do
    size = @user.access_keys.size
    @user.access_keys.get(@access_key_id).destroy
    @user.access_keys.size == ( size - 1 )
  end

  # clean up
  @user.access_keys.map(&:destroy)
  @user.destroy

end
