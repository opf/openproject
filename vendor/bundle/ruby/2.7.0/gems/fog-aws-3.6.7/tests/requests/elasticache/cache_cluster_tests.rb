Shindo.tests('AWS::Elasticache | cache cluster requests', ['aws', 'elasticache']) do

  tests('success') do

    # Randomize the cluster ID so tests can be fequently re-run
    CLUSTER_ID = "fog-test-cluster-#{rand(999).to_s}" # 20 chars max!
    NUM_NODES = 2   # Must be > 1, because one of the tests reomves a node!

    tests(
    '#create_cache_cluster'
    ).formats(AWS::Elasticache::Formats::SINGLE_CACHE_CLUSTER) do
      body = Fog::AWS[:elasticache].create_cache_cluster(CLUSTER_ID,
        :num_nodes => NUM_NODES
      ).body
      cluster = body['CacheCluster']
      returns(CLUSTER_ID) { cluster['CacheClusterId'] }
      returns('creating') { cluster['CacheClusterStatus'] }
      body
    end

    tests(
    '#describe_cache_clusters without options'
    ).formats(AWS::Elasticache::Formats::DESCRIBE_CACHE_CLUSTERS) do
      body = Fog::AWS[:elasticache].describe_cache_clusters.body
      returns(true, "has #{CLUSTER_ID}") do
        body['CacheClusters'].any? do |cluster|
          cluster['CacheClusterId'] == CLUSTER_ID
        end
      end
      # The DESCRIBE_CACHE_CLUSTERS format must include only one cluster
      # So remove all but the relevant cluster from the response body
      test_cluster = body['CacheClusters'].delete_if do |cluster|
        cluster['CacheClusterId'] != CLUSTER_ID
      end
      body
    end

    tests(
    '#describe_cache_clusters with cluster ID'
    ).formats(AWS::Elasticache::Formats::DESCRIBE_CACHE_CLUSTERS) do
      body = Fog::AWS[:elasticache].describe_cache_clusters(CLUSTER_ID).body
      returns(1, "size of 1") { body['CacheClusters'].size }
      returns(CLUSTER_ID, "has #{CLUSTER_ID}") do
        body['CacheClusters'].first['CacheClusterId']
      end
      body
    end

    Fog::Formatador.display_line "Waiting for cluster #{CLUSTER_ID}..."
    Fog::AWS[:elasticache].clusters.get(CLUSTER_ID).wait_for {ready?}

    tests(
    '#describe_cache_clusters with node info'
    ).formats(AWS::Elasticache::Formats::CACHE_CLUSTER_RUNNING) do
      cluster = Fog::AWS[:elasticache].describe_cache_clusters(CLUSTER_ID,
        :show_node_info => true
      ).body['CacheClusters'].first
      returns(NUM_NODES, "has #{NUM_NODES} nodes") do
        cluster['CacheNodes'].count
      end
      cluster
    end

    tests(
    '#modify_cache_cluster - change a non-pending cluster attribute'
    ).formats(AWS::Elasticache::Formats::CACHE_CLUSTER_RUNNING) do
      body = Fog::AWS[:elasticache].modify_cache_cluster(CLUSTER_ID,
        :auto_minor_version_upgrade => false
      ).body
      # now check that parameter change is in place
      returns('false')  { body['CacheCluster']['AutoMinorVersionUpgrade'] }
      body['CacheCluster']
    end

    tests(
    '#reboot_cache_cluster - reboot a node'
    ).formats(AWS::Elasticache::Formats::CACHE_CLUSTER_RUNNING) do
      c = Fog::AWS[:elasticache].clusters.get(CLUSTER_ID)
      node_id = c.nodes.last['CacheNodeId']
      Fog::Formatador.display_line "Rebooting node #{node_id}..."
      body = Fog::AWS[:elasticache].reboot_cache_cluster(c.id, [ node_id ]).body
      returns('rebooting cache cluster nodes') do
        body['CacheCluster']['CacheClusterStatus']
      end
      body['CacheCluster']
    end

    Fog::Formatador.display_line "Waiting for cluster #{CLUSTER_ID}..."
    Fog::AWS[:elasticache].clusters.get(CLUSTER_ID).wait_for {ready?}

    tests(
    '#modify_cache_cluster - remove a node'
    ).formats(AWS::Elasticache::Formats::CACHE_CLUSTER_RUNNING) do
      c = Fog::AWS[:elasticache].clusters.get(CLUSTER_ID)
      node_id = c.nodes.last['CacheNodeId']
      Fog::Formatador.display_line "Removing node #{node_id}..."
      body = Fog::AWS[:elasticache].modify_cache_cluster(c.id,
      {
        :num_nodes          => NUM_NODES - 1,
        :nodes_to_remove    => [node_id],
        :apply_immediately  => true,
      }).body
      returns(node_id) {
        body['CacheCluster']['PendingModifiedValues']['CacheNodeId']
      }
      body['CacheCluster']
    end

    Fog::Formatador.display_line "Waiting for cluster #{CLUSTER_ID}..."
    Fog::AWS[:elasticache].clusters.get(CLUSTER_ID).wait_for {ready?}

    tests(
    '#delete_cache_clusters'
    ).formats(AWS::Elasticache::Formats::CACHE_CLUSTER_RUNNING) do
      body = Fog::AWS[:elasticache].delete_cache_cluster(CLUSTER_ID).body
      # make sure this particular cluster is in the returned list
      returns(true, "has #{CLUSTER_ID}") do
        body['CacheClusters'].any? do |cluster|
          cluster['CacheClusterId'] == CLUSTER_ID
        end
      end
      # now check that it reports itself as 'deleting'
      cluster = body['CacheClusters'].find do |cluster|
        cluster['CacheClusterId'] == CLUSTER_ID
      end
      returns('deleting')  { cluster['CacheClusterStatus'] }
      cluster
    end
  end

  tests('failure') do
    # TODO:
    # Create a duplicate cluster ID
    # List a missing cache cluster
    # Delete a missing cache cluster
  end
end
