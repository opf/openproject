Shindo.tests("AWS::RDS | clusters", ["aws", "rds"]) do
  collection_tests(Fog::AWS[:rds].clusters, rds_default_cluster_params) do
    @instance.wait_for { ready? }
  end
end
