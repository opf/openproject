Shindo.tests("Fog::Compute[:iam] | groups", ['aws','iam']) do

  service     = Fog::AWS[:iam]
  group_name  = uniq_id('fog-test-group')
  policy_name = uniq_id('fog-test-policy')
  group       = nil
  document    = {"Statement" => [{"Effect" => "Allow", "Action" => "*", "Resource" => "*"}]}

  tests('#create').succeeds do
    group = service.groups.create(:name => group_name)

    group.name == group_name
  end

  tests('#all').succeeds do
    service.groups.all.map(&:name).include?(group_name)
  end

  tests('update').succeeds do
    new_path = group.path = "/newpath/"
    group.save

    group.reload.path == new_path
  end

  tests('group') do
    policy = nil

    tests('#policies', '#create') do
      policy = group.policies.create(:id => policy_name, :document => document)
    end

    tests('#policies', '#get').succeeds do
      group.policies.get(policy_name) != nil
    end

    tests('#policies', '#all').succeeds do
      group.policies.all.map(&:id).include?(policy.id)
    end

    tests('#users', 'when none').succeeds do
      group.users.empty?
    end

    user = nil

    tests('#add_user').succeeds do
      user = service.users.create(:id => 'fog-test')

      group.add_user(user)

      group.users.include?(user)
    end

    tests('#users').succeeds do
      group.reload.users.map(&:identity).include?(user.identity)
    end
  end
end
