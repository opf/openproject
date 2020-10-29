class AWS
  module RDS
    module Formats
      BASIC = {
        'ResponseMetadata' => { 'RequestId' => String }
      }

      DB_AVAILABILITY_ZONE_OPTION = {
        'Name' => String
      }

      DB_PARAMETER_GROUP = {
        'DBParameterGroupFamily' => String,
        'DBParameterGroupName' => String,
        'Description' => String
      }
      CREATE_DB_PARAMETER_GROUP = {
        'ResponseMetadata' => { 'RequestId' => String },
        'CreateDBParameterGroupResult' => {
          'DBParameterGroup' => DB_PARAMETER_GROUP
        }
      }

      DB_SECURITY_GROUP = {
        'DBSecurityGroupDescription' => String,
        'DBSecurityGroupName' => String,
        'EC2SecurityGroups' => [Fog::Nullable::Hash],
        'IPRanges' => [Fog::Nullable::Hash],
        'OwnerId' => Fog::Nullable::String
      }

      CREATE_DB_SECURITY_GROUP = BASIC.merge({
        'CreateDBSecurityGroupResult' => {
          'DBSecurityGroup' => DB_SECURITY_GROUP
        }
      })

      AUTHORIZE_DB_SECURITY_GROUP = BASIC.merge({
        'AuthorizeDBSecurityGroupIngressResult' => {
          'DBSecurityGroup' => DB_SECURITY_GROUP
        }
      })

      REVOKE_DB_SECURITY_GROUP = BASIC.merge({
        'RevokeDBSecurityGroupIngressResult' => {
          'DBSecurityGroup' => DB_SECURITY_GROUP
        }
      })

      DESCRIBE_DB_SECURITY_GROUP = BASIC.merge({
        'DescribeDBSecurityGroupsResult' => {
          'DBSecurityGroups' => [DB_SECURITY_GROUP]
        }
      })

      DB_SUBNET_GROUP = {
        'DBSubnetGroupName' => String,
        'DBSubnetGroupDescription' => String,
        'SubnetGroupStatus' => String,
        'VpcId' => String,
        'Subnets' => [String]
      }

      CREATE_DB_SUBNET_GROUP = BASIC.merge({
        'CreateDBSubnetGroupResult' => {
          'DBSubnetGroup' => DB_SUBNET_GROUP
        }
      })

      DESCRIBE_DB_SUBNET_GROUPS = BASIC.merge({
        'DescribeDBSubnetGroupsResult' => {
          'DBSubnetGroups' => [DB_SUBNET_GROUP]
        }
      })

      DESCRIBE_DB_PARAMETER_GROUP = {
        'ResponseMetadata' => { 'RequestId' => String },
        'DescribeDBParameterGroupsResult' => {
          'DBParameterGroups' => [DB_PARAMETER_GROUP]
        }
      }

      ORDERABLE_DB_INSTANCE_OPTION = {
        'MultiAZCapable' => Fog::Boolean,
        'Engine' => String,
        'LicenseModel' => String,
        'ReadReplicaCapable' => Fog::Boolean,
        'EngineVersion' => String,
        'AvailabilityZones' => [DB_AVAILABILITY_ZONE_OPTION],
        'DBInstanceClass' => String,
        'SupportsStorageEncryption' => Fog::Boolean,
        'SupportsPerformanceInsights' => Fog::Boolean,
        'StorageType' => String,
        'SupportsIops' => Fog::Boolean,
        'SupportsIAMDatabaseAuthentication' => Fog::Boolean,
        'SupportsEnhancedMonitoring' => Fog::Boolean,
        'Vpc' => Fog::Boolean
      }

      DESCRIBE_ORDERABLE_DB_INSTANCE_OPTION = BASIC.merge({
        'DescribeOrderableDBInstanceOptionsResult' => {
          'OrderableDBInstanceOptions' => [ORDERABLE_DB_INSTANCE_OPTION]
        }
      })

      MODIFY_PARAMETER_GROUP = BASIC.merge({
        'ModifyDBParameterGroupResult' => {
          'DBParameterGroupName' => String
        }
      })

      DB_PARAMETER = {
        'ParameterValue' => Fog::Nullable::String,
        'DataType' => String,
        'AllowedValues' => Fog::Nullable::String,
        'Source' => String,
        'IsModifiable' => Fog::Boolean,
        'Description' => String,
        'ParameterName' => String,
        'ApplyType' => String
      }

      DESCRIBE_DB_PARAMETERS = BASIC.merge({
        'DescribeDBParametersResult' => {
          'Marker' => Fog::Nullable::String,
          'Parameters' => [DB_PARAMETER]
        }

      })

      DB_LOG_FILE = {
        'LastWritten' => Time,
        'Size' => Integer,
        'LogFileName' => String
      }

      DESCRIBE_DB_LOG_FILES = BASIC.merge({
        'DescribeDBLogFilesResult' => {
          'Marker' => Fog::Nullable::String,
          'DBLogFiles' => [DB_LOG_FILE]
        }
      })

      SNAPSHOT = {
        'AllocatedStorage' => Integer,
        'AvailabilityZone' => Fog::Nullable::String,
        'DBInstanceIdentifier' => String,
        'DBSnapshotIdentifier' => String,
        'EngineVersion' => String,
        'Engine' => String,
        'InstanceCreateTime' => Time,
        'Iops' => Fog::Nullable::Integer,
        'MasterUsername' => String,
        'Port' => Fog::Nullable::Integer,
        'SnapshotCreateTime' => Fog::Nullable::Time,
        'Status' => String,
        'SnapshotType' => String,
        'StorageType' => String,
      }

      INSTANCE = {
        'AllocatedStorage'        => Integer,
        'AutoMinorVersionUpgrade' => Fog::Boolean,
        'AvailabilityZone'        => Fog::Nullable::String,
        'BackupRetentionPeriod'   => Integer,
        'CACertificateIdentifier' => String,
        'CharacterSetName'        => Fog::Nullable::String,
        'DBClusterIndentifier'    => Fog::Nullable::String,
        'DbiResourceId'           => Fog::Nullable::String,
        'DBInstanceClass'         => String,
        'DBInstanceIdentifier'    => String,
        'DBInstanceStatus'        => String,
        'DBName'                  => Fog::Nullable::String,
        'DBParameterGroups' => [{
          'ParameterApplyStatus' => String,
          'DBParameterGroupName' => String
        }],
        'DBSecurityGroups' => [{
          'Status'              => String,
          'DBSecurityGroupName' => String
        }],
        'DBSubnetGroupName'  => Fog::Nullable::String,
        'PubliclyAccessible' => Fog::Boolean,
        'Endpoint' => {
          'Address' => Fog::Nullable::String,
          'Port'    => Fog::Nullable::Integer
        },
        'Engine'               => String,
        'EngineVersion'        => String,
        'InstanceCreateTime'   => Fog::Nullable::Time,
        'Iops'                 => Fog::Nullable::Integer,
        'KmsKeyId'             => Fog::Nullable::String,
        'LatestRestorableTime' => Fog::Nullable::Time,
        'LicenseModel'         => String,
        'MasterUsername'       => String,
        'MultiAZ'              => Fog::Boolean,
        'PendingModifiedValues' => {
          'BackupRetentionPeriod' => Fog::Nullable::Integer,
          'DBInstanceClass'       => Fog::Nullable::String,
          'EngineVersion'         => Fog::Nullable::String,
          'MasterUserPassword'    => Fog::Nullable::String,
          'MultiAZ'               => Fog::Nullable::Boolean,
          'AllocatedStorage'      => Fog::Nullable::Integer,
          'Port'                  => Fog::Nullable::Integer
        },
        'PreferredBackupWindow'            => String,
        'PreferredMaintenanceWindow'       => String,
        'ReadReplicaDBInstanceIdentifiers' => [Fog::Nullable::String],
        'StorageType'                      => String,
        'StorageEncrypted'                 => Fog::Boolean,
        'TdeCredentialArn'                 => Fog::Nullable::String
      }

      REPLICA_INSTANCE = INSTANCE.merge({
        'PreferredBackupWindow'                 => Fog::Nullable::String,
        'ReadReplicaSourceDBInstanceIdentifier' => String
      })

      CREATE_DB_INSTANCE = BASIC.merge({
        'CreateDBInstanceResult' => {
          'DBInstance' => INSTANCE
        }
      })

      DESCRIBE_DB_INSTANCES = BASIC.merge({
        'DescribeDBInstancesResult' =>  {
          'Marker' => Fog::Nullable::String,
          'DBInstances' => [INSTANCE]
        }
      })

      MODIFY_DB_INSTANCE = BASIC.merge({
        'ModifyDBInstanceResult' => {
          'DBInstance' => INSTANCE
        }
      })

      DELETE_DB_INSTANCE = BASIC.merge({
        'DeleteDBInstanceResult' => {
          'DBInstance' => INSTANCE
        }
      })

      REBOOT_DB_INSTANCE = BASIC.merge({
        'RebootDBInstanceResult' => {
          'DBInstance' => INSTANCE
        }
      })

      CREATE_READ_REPLICA = BASIC.merge({
        'CreateDBInstanceReadReplicaResult' => {
          'DBInstance' => REPLICA_INSTANCE
        }
      })

      PROMOTE_READ_REPLICA = BASIC.merge({
        'PromoteReadReplicaResult' => {
          'DBInstance' => INSTANCE
        }
      })

      CREATE_DB_SNAPSHOT = BASIC.merge({
        'CreateDBSnapshotResult' => {
          'DBSnapshot' => SNAPSHOT
        }
      })

      DESCRIBE_DB_SNAPSHOTS = BASIC.merge({
        'DescribeDBSnapshotsResult' => {
          'Marker' => Fog::Nullable::String,
          'DBSnapshots' => [SNAPSHOT]
        }
      })
      DELETE_DB_SNAPSHOT = BASIC.merge({
        'DeleteDBSnapshotResult' => {
          'DBSnapshot' => SNAPSHOT
        }
      })

      LIST_TAGS_FOR_RESOURCE = {
        'ListTagsForResourceResult' => {
          'TagList' => Fog::Nullable::Hash
        }
      }

      EVENT_SUBSCRIPTION = {
        'CustSubscriptionId' => String,
        'EventCategories'    => Array,
        'SourceType'         => Fog::Nullable::String,
        'Enabled'            => String,
        'Status'             => String,
        'CreationTime'       => Time,
        'SnsTopicArn'        => String
      }

      CREATE_EVENT_SUBSCRIPTION = {
        'CreateEventSubscriptionResult' => {
          'EventSubscription' => EVENT_SUBSCRIPTION
        }
      }

      DESCRIBE_EVENT_SUBSCRIPTIONS = {
        'DescribeEventSubscriptionsResult' => {
          'EventSubscriptionsList' => [EVENT_SUBSCRIPTION]
        }
      }

      DB_ENGINE_VERSION = {
        'Engine'                     => String,
        'DBParameterGroupFamily'     => String,
        'DBEngineDescription'        => String,
        'EngineVersion'              => String,
        'DBEngineVersionDescription' => String
      }

      DB_ENGINE_VERSIONS_LIST = BASIC.merge(
        'DescribeDBEngineVersionsResult' => {
          'DBEngineVersions' => [DB_ENGINE_VERSION]
        }
      )

      DB_CLUSTER = {
        'AllocatedStorage'           => String,
        'BackupRetentionPeriod'      => String,
        'DBClusterIdentifier'        => String,
        'DBClusterMembers'           => [{
          "master"               => Fog::Nullable::Boolean,
          "DBInstanceIdentifier" => Fog::Nullable::String,
        }],
        'DBClusterParameterGroup'    => String,
        'DBSubnetGroup'              => String,
        'Endpoint'                   => String,
        'Engine'                     => String,
        'EngineVersion'              => String,
        'MasterUsername'             => String,
        'Port'                       => String,
        'PreferredBackupWindow'      => String,
        'PreferredMaintenanceWindow' => String,
        'Status'                     => String,
        'VpcSecurityGroups'          => [{
          "VpcSecurityGroupId" => Fog::Nullable::String,
        }]
      }

      DESCRIBE_DB_CLUSTERS = BASIC.merge({
        'DescribeDBClustersResult' =>  {
          'Marker' => Fog::Nullable::String,
          'DBClusters' => [DB_CLUSTER]
        }
      })

      CREATE_DB_CLUSTER = BASIC.merge(
        'CreateDBClusterResult' => {
          'DBCluster' => DB_CLUSTER
        }
      )

      DELETE_DB_CLUSTER = BASIC.merge(
        'DeleteDBClusterResult' => {
          'DBCluster' => DB_CLUSTER
        }
      )

      DB_CLUSTER_SNAPSHOT = {
        'AllocatedStorage'            => Fog::Nullable::Integer,
        'ClusterCreateTime'           => Fog::Nullable::Time,
        'DBClusterIdentifier'         => String,
        'DBClusterSnapshotIdentifier' => String,
        'Engine'                      => String,
        'LicenseModel'                => String,
        'MasterUsername'              => String,
        'PercentProgress'             => Fog::Nullable::Integer,
        'Port'                        => Fog::Nullable::Integer,
        'SnapshotCreateTime'          => Fog::Nullable::Time,
        'SnapshotType'                => String,
        'Status'                      => String,
        'VpcId'                       => Fog::Nullable::String
      }

      CREATE_DB_CLUSTER_SNAPSHOT = BASIC.merge(
        'CreateDBClusterSnapshotResult' => {
          'DBClusterSnapshot' => DB_CLUSTER_SNAPSHOT
        }
      )

      DESCRIBE_DB_CLUSTER_SNAPSHOTS = BASIC.merge(
        'DescribeDBClusterSnapshotsResult' => {
          'Marker'             => Fog::Nullable::String,
          'DBClusterSnapshots' => [DB_CLUSTER_SNAPSHOT],
        }
      )

      DELETE_DB_CLUSTER_SNAPSHOT = BASIC.merge(
        'DeleteDBClusterSnapshotResult' => {
          'DBClusterSnapshot' => DB_CLUSTER_SNAPSHOT,
        }
      )

      RESTORE_DB_INSTANCE_FROM_DB_SNAPSHOT = BASIC.merge({
        'RestoreDBInstanceFromDBSnapshotResult' => {
          'DBInstance' => INSTANCE
        }
      })
    end
  end
end
