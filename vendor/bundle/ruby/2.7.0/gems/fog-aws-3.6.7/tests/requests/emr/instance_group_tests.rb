Shindo.tests('AWS::EMR | instance groups', ['aws', 'emr']) do

  pending if Fog.mocking?

  @job_flow_name = "fog_job_flow_#{Time.now.to_f.to_s.gsub('.','')}"

  @job_flow_options = {
    'Instances' => {
      'MasterInstanceType' => 'm1.small',
      'SlaveInstanceType' => 'm1.small',
      'InstanceCount' => 2,
      'Placement' => {
        'AvailabilityZone' => 'us-east-1a'
      },
      'KeepJobFlowAliveWhenNoSteps' => false,
      'TerminationProtected' => false,
      'HadoopVersion' => '0.20'
    }
  }

  @job_flow_steps = {
    'Steps' => [{
      'Name' => 'Dummy streaming job',
      'ActionOnFailure' => 'CONTINUE',
      'HadoopJarStep' => {
        'Jar' => '/home/hadoop/contrib/streaming/hadoop-streaming.jar',
        'MainClass' => nil,
        'Args' => %w(-input s3n://elasticmapreduce/samples/wordcount/input -output hdfs:///examples/output/2011-11-03T090856 -mapper s3n://elasticmapreduce/samples/wordcount/wordSplitter.py -reducer aggregate)
      }
    }]
  }

  @instance_group_name = "fog_instance_group_#{Time.now.to_f.to_s.gsub('.','')}"
  @instance_groups = {
    'InstanceGroups' => [{
      'Name' => @instance_group_name,
      'InstanceRole' => 'TASK',
      'InstanceType' => 'm1.small',
      'InstanceCount' => 2
    }]
  }

  result = Fog::AWS[:emr].run_job_flow(@job_flow_name, @job_flow_options).body
  @job_flow_id = result['JobFlowId']

  tests('success') do

    tests("#add_instance_groups").formats(AWS::EMR::Formats::ADD_INSTANCE_GROUPS) do
      pending if Fog.mocking?

      result = Fog::AWS[:emr].add_instance_groups(@job_flow_id, @instance_groups).body

      @instance_group_id = result['InstanceGroupIds'].first

      result
    end

    tests("#describe_job_flows_with_instance_groups").formats(AWS::EMR::Formats::DESCRIBE_JOB_FLOW_WITH_INSTANCE_GROUPS) do
      pending if Fog.mocking?

      result = Fog::AWS[:emr].describe_job_flows('JobFlowIds' => [@job_flow_id]).body

      result
    end

    tests("#modify_instance_groups").formats(AWS::EMR::Formats::BASIC) do
      pending if Fog.mocking?

      # Add a step so the state doesn't go directly from STARTING to SHUTTING_DOWN
      Fog::AWS[:emr].add_job_flow_steps(@job_flow_id, @job_flow_steps)

      # Wait until job has started before modifying the instance group
      begin
        sleep 10

        result = Fog::AWS[:emr].describe_job_flows('JobFlowIds' => [@job_flow_id]).body
        job_flow = result['JobFlows'].first
        state = job_flow['ExecutionStatusDetail']['State']
        print "."
      end while(state == 'STARTING')

      # Check results
      result = Fog::AWS[:emr].modify_instance_groups('InstanceGroups' => [{'InstanceGroupId' => @instance_group_id, 'InstanceCount' => 4}]).body

      # Check the it actually modified the instance count
      tests("modify worked?") do
        ig_res = Fog::AWS[:emr].describe_job_flows('JobFlowIds' => [@job_flow_id]).body

        matched = false
        jf = ig_res['JobFlows'].first
        jf['Instances']['InstanceGroups'].each do | ig |
          if ig['InstanceGroupId'] == @instance_group_id
            matched = true if ig['InstanceRequestCount'].to_i == 4
          end
        end

        matched
      end

      result
    end

  end

  Fog::AWS[:emr].terminate_job_flows('JobFlowIds' => [@job_flow_id])
end
