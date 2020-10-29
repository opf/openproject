Shindo.tests('AWS::ElasticBeanstalk | solution_stack_tests', ['aws', 'beanstalk']) do

  tests('success') do
    pending if Fog.mocking?

    @solution_stack_result_format = {
        'ListAvailableSolutionStacksResult' => {
            'SolutionStackDetails' => [
               'SolutionStackName' => String,
              'PermittedFileTypes' => [String]
            ],
            'SolutionStacks' => [String]
        },
        'ResponseMetadata' => {'RequestId'=> String},
    }
    tests("#list_available_solution_stacks").formats(@solution_stack_result_format) do
      Fog::AWS[:beanstalk].list_available_solution_stacks.body

    end

  end
end
