Shindo.tests('AWS::AutoScaling | auto_scaling_tests', ['aws', 'auto_scaling']) do
  @asg_name = 'fog-test-asg'
  @lc_name = 'fog-test-lc'

  tests('success') do
    tests("#create_launch_configuration").formats(AWS::AutoScaling::Formats::BASIC) do
      image_id = 'ami-8c1fece5'
      instance_type = 't1.micro'
      #listeners = [{'LoadBalancerPort' => 80, 'InstancePort' => 80, 'Protocol' => 'http'}]
      Fog::AWS[:auto_scaling].create_launch_configuration(image_id, instance_type, @lc_name).body
    end

    tests("#describe_launch_configurations").formats(AWS::AutoScaling::Formats::DESCRIBE_LAUNCH_CONFIGURATIONS) do
      Fog::AWS[:auto_scaling].describe_launch_configurations().body
    end
    tests("#describe_launch_configurations").formats(AWS::AutoScaling::Formats::DESCRIBE_LAUNCH_CONFIGURATIONS) do
      Fog::AWS[:auto_scaling].describe_launch_configurations('LaunchConfigurationNames' => @lc_name).body
    end
    tests("#describe_launch_configurations").formats(AWS::AutoScaling::Formats::DESCRIBE_LAUNCH_CONFIGURATIONS) do
      Fog::AWS[:auto_scaling].describe_launch_configurations('LaunchConfigurationNames' => [@lc_name]).body
    end

    tests("#create_auto_scaling_group").formats(AWS::AutoScaling::Formats::BASIC) do
      zones = ['us-east-1d']
      max_size = 0
      min_size = 0
      Fog::AWS[:auto_scaling].create_auto_scaling_group(@asg_name, zones, @lc_name, max_size, min_size).body
    end

    if Fog.mocking?
      tests("#attach_load_balancers").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].attach_load_balancers(@asg_name, 'LoadBalancerNames' => 'elb-test-fog').body
      end

      tests("#detach_load_balancers").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].detach_load_balancers(@asg_name, 'LoadBalancerNames' => 'elb-test-fog').body
      end

      tests("#attach_load_balancer_target_groups").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].attach_load_balancer_target_groups(@asg_name, 'TargetGroupARNs' => 'elb-test-fog').body
      end

      tests("#detach_load_balancer_target_groups").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].detach_load_balancer_target_groups(@asg_name, 'TargetGroupARNs' => 'elb-test-fog').body
      end

      tests("#detach_instances").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].detach_instances(@asg_name, 'InstanceIds' => 'i-deadbeef').body
      end

      tests("#attach_instances").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].attach_instances(@asg_name, 'InstanceIds' => 'i-deadbeef').body
      end

      tests("#set_instance_protection").formats(AWS::AutoScaling::Formats::BASIC) do
        Fog::AWS[:auto_scaling].set_instance_protection(
          @asg_name,
          'InstanceIds' => 'i-deadbeef',
          'ProtectedFromScaleIn' => true
        ).body
      end
    end

    tests("#describe_auto_scaling_groups").formats(AWS::AutoScaling::Formats::DESCRIBE_AUTO_SCALING_GROUPS) do
      Fog::AWS[:auto_scaling].describe_auto_scaling_groups().body
    end
    tests("#describe_auto_scaling_groups").formats(AWS::AutoScaling::Formats::DESCRIBE_AUTO_SCALING_GROUPS) do
      Fog::AWS[:auto_scaling].describe_auto_scaling_groups('AutoScalingGroupNames' => @asg_name).body
    end
    tests("#describe_auto_scaling_groups").formats(AWS::AutoScaling::Formats::DESCRIBE_AUTO_SCALING_GROUPS) do
      Fog::AWS[:auto_scaling].describe_auto_scaling_groups('AutoScalingGroupNames' => [@asg_name]).body
    end

    tests("#describe_auto_scaling_instances").formats(AWS::AutoScaling::Formats::DESCRIBE_AUTO_SCALING_INSTANCES) do
      Fog::AWS[:auto_scaling].describe_auto_scaling_instances().body
    end

    tests("#describe_scaling_activities").formats(AWS::AutoScaling::Formats::DESCRIBE_SCALING_ACTIVITIES) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].describe_scaling_activities().body
    end
    tests("#describe_scaling_activities").formats(AWS::AutoScaling::Formats::DESCRIBE_SCALING_ACTIVITIES) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].describe_scaling_activities('ActivityIds' => '1').body
    end
    tests("#describe_scaling_activities").formats(AWS::AutoScaling::Formats::DESCRIBE_SCALING_ACTIVITIES) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].describe_scaling_activities('ActivityIds' => ['1', '2']).body
    end
    tests("#describe_scaling_activities").formats(AWS::AutoScaling::Formats::DESCRIBE_SCALING_ACTIVITIES) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].describe_scaling_activities('AutoScalingGroupName' => @asg_name).body
    end

    tests("#set_desired_capacity").formats(AWS::AutoScaling::Formats::BASIC) do
      desired_capacity = 0
      Fog::AWS[:auto_scaling].set_desired_capacity(@asg_name, desired_capacity).body
    end
    tests("#delete_auto_scaling_group").formats(AWS::AutoScaling::Formats::BASIC) do
      Fog::AWS[:auto_scaling].delete_auto_scaling_group(@asg_name, 'ForceDelete' => true).body
    end

    tests("#delete_auto_scaling_group that does not exists").raises(Fog::AWS::AutoScaling::ValidationError) do
      Fog::AWS[:auto_scaling].delete_auto_scaling_group("group that does not exist")
    end

    tests("#delete_launch_configuration").formats(AWS::AutoScaling::Formats::BASIC) do
      Fog::AWS[:auto_scaling].delete_launch_configuration(@lc_name).body
    end
  end
end
