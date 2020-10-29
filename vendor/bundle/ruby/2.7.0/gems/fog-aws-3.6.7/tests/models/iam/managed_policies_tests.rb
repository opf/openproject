Shindo.tests("Fog::Compute[:iam] | managed_policies", ['aws','iam']) do

  iam = Fog::AWS[:iam]

  tests('#all').succeeds do
    iam.managed_policies.size == 100
  end

  tests('#each').succeeds do
    policies = []

    iam.managed_policies.each { |policy| policies << policy }

    policies.size > 100
  end

  policy = iam.managed_policies.get("arn:aws:iam::aws:policy/IAMReadOnlyAccess")

  tests("#document").succeeds do
    policy.document == {
      "Version"   => "2012-10-17",
      "Statement" => [
        {
          "Effect"   => "Allow",
          "Action"   => [ "iam:GenerateCredentialReport", "iam:GenerateServiceLastAccessedDetails", "iam:Get*", "iam:List*" ],
          "Resource" => "*"
        }
      ]
    }
  end

  tests("users") do
    user = iam.users.create(:id => uniq_id("fog-test-user"))

    tests("#attach").succeeds do
      user.attach(policy)

      user.attached_policies.map(&:identity) == [policy.identity]
    end

    returns(1) { policy.reload.attachments}

    tests("#detach").succeeds do
      user.detach(policy)

      user.attached_policies.map(&:identity) == []
    end

    user.destroy
  end

  tests("groups") do
    group = iam.groups.create(:name => uniq_id("fog-test-group"))

    tests("#attach").succeeds do
      group.attach(policy)

      group.attached_policies.map(&:identity) == [policy.identity]
    end

    returns(1) { policy.reload.attachments}

    tests("#detach").succeeds do
      group.detach(policy)

      group.attached_policies.map(&:identity) == []
    end

    group.destroy
  end

  tests("roles") do
    role = iam.roles.create(:rolename => uniq_id("fog-test-role"))

    tests("#attach").succeeds do
      role.attach(policy)
      role.attached_policies.map(&:identity) == [policy.identity]
    end

    returns(1) { policy.reload.attachments}

    tests("#detach").succeeds do
      role.detach(policy)
      role.attached_policies.map(&:identity) == []
    end

    role.destroy
  end
end
