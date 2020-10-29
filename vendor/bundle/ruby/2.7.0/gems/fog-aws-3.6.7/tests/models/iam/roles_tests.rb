Shindo.tests("Fog::Compute[:iam] | roles", ['aws','iam']) do

  @iam = Fog::AWS[:iam]
  @role_one_name = 'fake_role_one'
  @role_two_name = 'fake_role_two'

  @role_three_name = 'fake_role_three'
  @role_three_path = '/path/to/fake_role_three/'
  @role_four_name  = 'fake_role_four'

  tests('#create').succeeds do
    @role_one = @iam.roles.create(:rolename => @role_one_name)
    @role_one.rolename == @role_one_name
  end

  tests('#all','there is only one role').succeeds do
    @iam.roles.size == 1
  end

  tests('#all','the only role should match').succeeds do
    @iam.roles.first.rolename == @role_one_name
  end

  tests('#create','a second role').succeeds do
    @role_two = @iam.roles.create(:rolename => @role_two_name)
    @role_two.rolename == @role_two_name
  end

  tests('#all','there are two roles').succeeds do
    @iam.roles.size == 2
  end

  tests('#get','an existing role').succeeds do
    @iam.roles.get(@role_one_name).rolename == @role_one_name
  end

  tests('#get',"returns nil if the role doesn't exists").succeeds do
    @iam.roles.get('blah').nil?
  end

  tests('#create', 'assigns path').succeeds do
    @role_three = @iam.roles.create(:rolename => @role_three_name, :path => @role_three_path)
    @role_three.path == @role_three_path
  end

  tests('#create', 'defaults path to /').succeeds do
    @role_four = @iam.roles.create(:rolename => @role_four_name)
    @role_four.path == '/'
  end

  tests('#destroy','an existing role').succeeds do
    @iam.roles.get(@role_one_name).destroy
  end

  tests('#all', 'limit 1').succeeds do
    1 == @iam.roles.all(:limit => 1).size
  end

  tests('#all', 'each_entry').succeeds do
    roles = []; @iam.roles.each(:limit => 1) { |r| roles << r }

    3 == roles.size
  end

  tests('#destroy','clean up remaining roles').succeeds do
    @iam.roles.get(@role_two_name).destroy
    @iam.roles.get(@role_three_name).destroy
    @iam.roles.get(@role_four_name).destroy
  end

end
