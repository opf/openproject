Shindo.tests('AWS::ECS | cluster requests', ['aws', 'ecs']) do

  Fog::AWS[:ecs].reset_data

  tests('success') do

    tests("#create_cluster").formats(AWS::ECS::Formats::CREATE_CLUSTER) do
      result = Fog::AWS[:ecs].create_cluster('clusterName' => 'cluster1').body
      cluster = result['CreateClusterResult']['cluster']
      returns('cluster1') { cluster['clusterName'] }
      returns('ACTIVE') { cluster['status'] }
      result
    end

    tests("#create_cluster another").formats(AWS::ECS::Formats::CREATE_CLUSTER) do
      result = Fog::AWS[:ecs].create_cluster('clusterName' => 'foobar').body
      cluster = result['CreateClusterResult']['cluster']
      returns('foobar') { cluster['clusterName'] }
      returns('ACTIVE') { cluster['status'] }
      result
    end

    tests("#create_cluster without params").formats(AWS::ECS::Formats::CREATE_CLUSTER) do
      result = Fog::AWS[:ecs].create_cluster.body
      cluster = result['CreateClusterResult']['cluster']
      returns('default') { cluster['clusterName'] }
      result
    end

    tests("#list_clusters").formats(AWS::ECS::Formats::LIST_CLUSTERS) do
      result = Fog::AWS[:ecs].list_clusters.body
      clusters = result['ListClustersResult']['clusterArns']
      returns(true) { clusters.size.eql?(3) }
      result
    end

    tests("#describe_clusters with name").formats(AWS::ECS::Formats::DESCRIBE_CLUSTERS) do
      result = Fog::AWS[:ecs].describe_clusters('clusters' => 'cluster1').body
      clusters = result['DescribeClustersResult']['clusters']
      failures = result['DescribeClustersResult']['failures']
      returns(true) { clusters.size.eql?(1) }
      returns('cluster1') { clusters.first['clusterName'] }
      returns(true) { failures.empty? }
      result
    end

    tests("#describe_clusters without params").formats(AWS::ECS::Formats::DESCRIBE_CLUSTERS) do
      result = Fog::AWS[:ecs].describe_clusters.body
      clusters = result['DescribeClustersResult']['clusters']
      failures = result['DescribeClustersResult']['failures']
      returns(true) { clusters.size.eql?(1) }
      returns('default') { clusters.first['clusterName'] }
      result
    end

    tests("#describe_clusters several with name").formats(AWS::ECS::Formats::DESCRIBE_CLUSTERS) do
      result = Fog::AWS[:ecs].describe_clusters('clusters' => %w(cluster1 foobar)).body
      clusters = result['DescribeClustersResult']['clusters']
      cluster_names = clusters.map { |c| c['clusterName'] }.sort
      returns(true) { clusters.size.eql?(2) }
      returns('cluster1') { cluster_names.first }
      returns('foobar') { cluster_names[1] }
      result
    end

    tests("#describe_clusters with errors").formats(AWS::ECS::Formats::DESCRIBE_CLUSTERS) do
      result = Fog::AWS[:ecs].describe_clusters('clusters' => %w(foobar not_here wtf)).body
      clusters = result['DescribeClustersResult']['clusters']
      failures = result['DescribeClustersResult']['failures']
      returns(true) { failures.size.eql?(2) }
      returns('MISSING') { failures.first['reason'] }
      returns(true) { clusters.size.eql?(1) }
      result
    end

    tests("#delete_cluster").formats(AWS::ECS::Formats::DELETE_CLUSTER) do
      cluster_name = 'foobar'
      result = Fog::AWS[:ecs].delete_cluster('cluster' => cluster_name).body
      cluster = result['DeleteClusterResult']['cluster']
      returns(true) { cluster['clusterName'].eql?(cluster_name) }
      returns('INACTIVE') { cluster['status'] }
      result
    end

    tests("#list_clusters after one delete").formats(AWS::ECS::Formats::LIST_CLUSTERS) do
      result = Fog::AWS[:ecs].list_clusters.body
      clusters = result['ListClustersResult']['clusterArns']
      returns(true) { clusters.size.eql?(2) }
      result
    end

    tests("#delete_cluster by arn").formats(AWS::ECS::Formats::DELETE_CLUSTER) do
      result1 = Fog::AWS[:ecs].describe_clusters.body
      cluster1 = result1['DescribeClustersResult']['clusters'].first
      result2 = Fog::AWS[:ecs].delete_cluster('cluster' => cluster1['clusterArn']).body
      cluster2 = result2['DeleteClusterResult']['cluster']
      returns('default') { cluster2['clusterName'] }
      returns('INACTIVE') { cluster2['status'] }
      result2
    end

  end

  tests('failures') do

    tests('#delete_cluster without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].delete_cluster.body
    end

  end

end
