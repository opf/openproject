class AWS
  module Elasticache
    module Formats
      BASIC = {
        'ResponseMetadata' => {'RequestId' => String}
      }

      # Cache Security Groups
      SECURITY_GROUP = {
        'EC2SecurityGroups'       => Array,
        'CacheSecurityGroupName'  => String,
        'Description'             => String,
        'OwnerId'                 => String,
      }
      SINGLE_SECURITY_GROUP = BASIC.merge('CacheSecurityGroup' => SECURITY_GROUP)
      DESCRIBE_SECURITY_GROUPS = {'CacheSecurityGroups' => [SECURITY_GROUP]}

      CACHE_SUBNET_GROUP = {
        'CacheSubnetGroupName' => String,
        'CacheSubnetGroupDescription' => String,
        'VpcId' => String,
        'Subnets' => [String]
      }

      CREATE_CACHE_SUBNET_GROUP = BASIC.merge({
         'CreateCacheSubnetGroupResult' => {
           'CacheSubnetGroup' => CACHE_SUBNET_GROUP
         }
       })

      DESCRIBE_CACHE_SUBNET_GROUPS = BASIC.merge({
        'DescribeCacheSubnetGroupsResult' => {
          'CacheSubnetGroups' => [CACHE_SUBNET_GROUP]
        }
      })

      # Cache Parameter Groups
      PARAMETER_GROUP = {
        'CacheParameterGroupFamily' => String,
        'CacheParameterGroupName'   => String,
        'Description'               => String,
      }
      SINGLE_PARAMETER_GROUP = BASIC.merge('CacheParameterGroup' => PARAMETER_GROUP)
      DESCRIBE_PARAMETER_GROUPS = BASIC.merge('CacheParameterGroups' => [PARAMETER_GROUP])
      MODIFY_PARAMETER_GROUP = {'CacheParameterGroupName' => String }
      PARAMETER_SET = {
        'Parameters'                      => Array,
        'CacheNodeTypeSpecificParameters' => Array,
      }
      ENGINE_DEFAULTS = PARAMETER_SET.merge('CacheParameterGroupFamily' => String)
      # Cache Clusters - more parameters get added as the lifecycle progresses
      CACHE_CLUSTER = {
        'AutoMinorVersionUpgrade'     => String,  # actually TrueClass or FalseClass
        'CacheSecurityGroups'         => Array,
        'CacheClusterId'              => String,
        'CacheClusterStatus'          => String,
        'CacheNodeType'               => String,
        'Engine'                      => String,
        'EngineVersion'               => String,
        'CacheParameterGroup'         => Hash,
        'NumCacheNodes'               => Integer,
        'PreferredMaintenanceWindow'  => String,
        'CacheNodes'                  => Array,
        'PendingModifiedValues'       => Hash,
      }
      CACHE_CLUSTER_RUNNING   = CACHE_CLUSTER.merge({
        'CacheClusterCreateTime'      => DateTime,
        'PreferredAvailabilityZone'   => String,
      })
      CACHE_CLUSTER_MODIFIED  = CACHE_CLUSTER_RUNNING.merge({
        'NotificationConfiguration'   => Hash,
        'PendingModifiedValues'       => Hash,
      })
      SINGLE_CACHE_CLUSTER    = BASIC.merge('CacheCluster' => CACHE_CLUSTER)
      DESCRIBE_CACHE_CLUSTERS = BASIC.merge('CacheClusters' => [CACHE_CLUSTER])

      EVENT = {
        'Date'                        => DateTime,
        'Message'                     => String,
        'SourceIdentifier'            => String,
        'SourceType'                  => String,
      }
      EVENT_LIST = [EVENT]

      RESERVED_CACHE_CLUSTER = {
        'CacheNodeCount'                => Integer,
        'CacheNodeType'                 => String,
        'Duration'                      => Integer,
        'FixedPrice'                    => Float,
        'OfferingType'                  => String,
        'ProductDescription'            => String,
        'RecurringCharges'              => Array,
        'ReservedCacheNodeId'           => String,
        'ReservedCacheNodesOfferingId'  => String,
        'StartTime'                     => DateTime,
        'State'                         => String,
        'UsagePrice'                    => Float
      }
      RESERVED_CACHE_CLUSTER_LIST = [RESERVED_CACHE_CLUSTER]

    end
  end
end
