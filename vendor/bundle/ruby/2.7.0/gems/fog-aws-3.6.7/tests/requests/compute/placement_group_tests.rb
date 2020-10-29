Shindo.tests('Fog::Compute[:aws] | placement group requests', ['aws']) do
  @placement_group_format = {
    'requestId'         => String,
    'placementGroupSet' => [{
      'groupName' => String,
      'state'     => String,
      'strategy'  => String
    }]
  }

  tests('success') do
    tests("#create_placement_group('fog_placement_group', 'cluster')").formats(AWS::Compute::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::Compute[:aws].create_placement_group('fog_placement_group', 'cluster').body
    end

    tests("#describe_placement_groups").formats(@placement_group_format) do
      pending if Fog.mocking?
      Fog::Compute[:aws].describe_placement_groups.body
    end

    tests("#describe_placement_groups('group-name' => 'fog_placement_group)").formats(@placement_group_format) do
      pending if Fog.mocking?
      Fog::Compute[:aws].describe_placement_groups('group-name' => 'fog_security_group').body
    end

    tests("#delete_placement_group('fog_placement_group')").formats(AWS::Compute::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::Compute[:aws].delete_placement_group('fog_placement_group').body
    end
  end

  tests('failure') do
    pending if Fog.mocking?

    Fog::Compute[:aws].create_placement_group('fog_placement_group', 'cluster')

    tests("duplicate #create_placement_group('fog_placement_group', 'cluster')").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].create_placement_group('fog_placement_group', 'cluster')
    end

    tests("#delete_placement_group('not_a_group_name')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].delete_placement_group('not_a_group_name')
    end

    Fog::Compute[:aws].delete_placement_group('fog_placement_group')
  end
end
