Shindo.tests('AWS::Elasticache | cache clusters', ['aws', 'elasticache']) do
  cluster_params = {
    :id               => "fog-test-cluster-#{rand(999).to_s}",
    :node_type        => 'cache.m1.large',
    :security_groups  => ['default'],
    :engine           => 'memcached',
    :num_nodes        => 1
  }

  pending if Fog.mocking?

  Fog::Formatador.display_line "Creating cluster #{cluster_params[:id]}..."
  model_tests(Fog::AWS[:elasticache].clusters, cluster_params, false) do
    @instance.reload  # Reload to get the cluster info from AWS
    Fog::Formatador.display_line "Waiting for #{@instance.id} "+
      "to become available (#{@instance.status})..."
    @instance.wait_for {ready?}
  end

  # Single model is still deleting, so re-randomize the cluster ID
  cluster_params[:id] = "fog-test-cluster-#{rand(999).to_s}"
  Fog::Formatador.display_line "Creating cluster #{cluster_params[:id]}..."
  collection_tests(Fog::AWS[:elasticache].clusters, cluster_params, false) do
    @instance.reload  # Reload to get the cluster info from AWS
    Fog::Formatador.display_line "Waiting for #{@instance.id} "+
      "to become available (#{@instance.status})..."
    @instance.wait_for {ready?}
  end

end
