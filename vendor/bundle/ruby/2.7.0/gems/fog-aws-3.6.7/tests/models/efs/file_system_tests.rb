Shindo.tests("AWS::EFS | file system", ["aws", "efs"]) do
  file_system_params = {
    :creation_token => "fogtoken#{rand(999).to_s}"
  }

  model_tests(Fog::AWS[:efs].file_systems, file_system_params, true)

  file_system_params = {
    :creation_token => "fogtoken#{rand(999).to_s}"
  }
  collection_tests(Fog::AWS[:efs].file_systems, file_system_params, true)
end
