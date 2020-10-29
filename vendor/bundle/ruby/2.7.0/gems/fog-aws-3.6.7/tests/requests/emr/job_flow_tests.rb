Shindo.tests('AWS::EMR | job flows', ['aws', 'emr']) do

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

  @step_name = "fog_job_flow_step_#{Time.now.to_f.to_s.gsub('.','')}"

  @job_flow_steps = {
    'Steps' => [{
      'Name' => @step_name,
      'ActionOnFailure' => 'CONTINUE',
      'HadoopJarStep' => {
        'Jar' => 'FakeJar',
        'MainClass' => 'FakeMainClass',
        'Args' => ['arg1', 'arg2']
      }
    }]
  }

  @job_flow_id = nil

  tests('success') do

    tests("#run_job_flow").formats(AWS::EMR::Formats::RUN_JOB_FLOW) do
      pending if Fog.mocking?

      result = Fog::AWS[:emr].run_job_flow(@job_flow_name, @job_flow_options).body
      @job_flow_id = result['JobFlowId']

      result
    end

    tests("#add_job_flow_steps").formats(AWS::EMR::Formats::BASIC) do
      pending if Fog.mocking?

      result = Fog::AWS[:emr].add_job_flow_steps(@job_flow_id, @job_flow_steps).body

      result
    end

    tests("#set_termination_protection").formats(AWS::EMR::Formats::BASIC) do

      result = Fog::AWS[:emr].set_termination_protection(true, 'JobFlowIds' => [@job_flow_id]).body

      test("protected?") do
        res = Fog::AWS[:emr].describe_job_flows('JobFlowIds' => [@job_flow_id]).body
        jf = res['JobFlows'].first

        jf['Instances']['TerminationProtected'] == 'true'
      end

      result
    end

    tests("#terminate_job_flow").formats(AWS::EMR::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:emr].set_termination_protection(false, 'JobFlowIds' => [@job_flow_id])

      result = Fog::AWS[:emr].terminate_job_flows('JobFlowIds' => [@job_flow_id]).body

      result
    end

    tests("#describe_job_flows").formats(AWS::EMR::Formats::SIMPLE_DESCRIBE_JOB_FLOW) do
      pending if Fog.mocking?

      result = Fog::AWS[:emr].describe_job_flows('JobFlowIds' => [@job_flow_id]).body

      result
    end

  end
end
