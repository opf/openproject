Shindo.tests('AWS::Elasticache | security groups', ['aws', 'elasticache']) do
  group_name = 'fog-test'
  description = 'Fog Test'

  pending if Fog.mocking?

  model_tests(
  Fog::AWS[:elasticache].security_groups,
  {:id => group_name, :description => description}, false
  ) do

    # An EC2 group to authorize
    ec2_group = Fog::Compute.new(:provider => 'AWS').security_groups.create(
      :name => 'fog-test-elasticache', :description => 'fog test'
    )

    # Reload to get the instance owner_id
    @instance.reload

    tests('#authorize_ec2_group') do
      @instance.authorize_ec2_group(ec2_group.name)
      returns('authorizing') do
        group = @instance.ec2_groups.find do |g|
          g['EC2SecurityGroupName'] == ec2_group.name
        end
        group['Status']
      end
      returns(false, 'not ready') { @instance.ready? }
    end

    @instance.wait_for { ready? }

    tests('#revoke_ec2_group') do
      @instance.revoke_ec2_group(ec2_group.name)
      returns('revoking') do
        group = @instance.ec2_groups.find do |g|
          g['EC2SecurityGroupName'] == ec2_group.name
        end
        group['Status']
      end
      returns(false, 'not ready') { @instance.ready? }
    end

    ec2_group.destroy
  end

  collection_tests(
    Fog::AWS[:elasticache].security_groups,
    {:id => group_name, :description => description}, false
  )

end
