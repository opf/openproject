Shindo.tests("Fog::Compute[:iam] | policies", ['aws','iam']) do

  iam = Fog::AWS[:iam]

  @username = 'fake_user'
  @user = iam.users.create(:id => @username)
  @policy_document = {"Statement"=>[{"Action"=>["sqs:*"], "Effect"=>"Allow", "Resource"=>"*"}]}
  @policy_name = 'fake-sqs-policy'

  tests('#all', 'there is no policies').succeeds do
    @user.policies.empty?
  end

  tests('#create') do
    tests('a valid policy').succeeds do
      policy = @user.policies.create(:id => @policy_name, :document => @policy_document)
      policy.id == @policy_name
      policy.username == @username
      policy.document == @policy_document
    end

    # The mocking doesn't validate the document policy
    #tests('an invalid valid policy').succeeds do
    #  raises(Fog::AWS::IAM::Error) { @user.policies.create(id: 'non-valid-document', document: 'invalid json blob') }
    #end
  end

  @user.policies.create(:id => 'another-policy', :document => {})

  tests('#all','there are two policies').succeeds do
    @user.policies.size == 2
  end

  tests('#get') do
    tests('a valid policy').succeeds do
      policy = @user.policies.get(@policy_name)
      policy.id == @polic_name
      policy.username == @username
      policy.document == @policy_document
    end

    tests('an invalid policy').succeeds do
      @user.policies.get('non-existing') == nil
    end
  end

  tests('#destroy').succeeds do
    @user.policies.get(@policy_name).destroy
  end

  # clean up
  @user.access_keys.map(&:destroy)
  @user.policies.map(&:destroy)
  @user.destroy


end
