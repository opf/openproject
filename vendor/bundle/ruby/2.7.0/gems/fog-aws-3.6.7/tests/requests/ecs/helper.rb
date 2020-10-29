class AWS
  module ECS
    module Formats
      BASIC = {
        'ResponseMetadata' => { 'RequestId' => String }
      }
      CREATE_CLUSTER = BASIC.merge({
        'CreateClusterResult' => {
          'cluster' => {
            'clusterName'                       => String,
            'clusterArn'                        => String,
            'status'                            => String,
            'registeredContainerInstancesCount' => Integer,
            'runningTasksCount'                 => Integer,
            'pendingTasksCount'                 => Integer
          }
        }
      })
      LIST_CLUSTERS = BASIC.merge({
        'ListClustersResult' => {
          'clusterArns' => [String],
          'nextToken'   => Fog::Nullable::String
        }
      })
      DELETE_CLUSTER = BASIC.merge({
        'DeleteClusterResult' => {
          'cluster' => {
            'clusterName'                       => String,
            'clusterArn'                        => String,
            'status'                            => String,
            'registeredContainerInstancesCount' => Integer,
            'runningTasksCount'                 => Integer,
            'pendingTasksCount'                 => Integer
          }
        }
      })
      DESCRIBE_CLUSTERS = BASIC.merge({
        'DescribeClustersResult' => {
          'failures' => [Fog::Nullable::Hash],
          'clusters' => [Fog::Nullable::Hash]
        }
      })
      REGISTER_TASK_DEFINITION = BASIC.merge({
        'RegisterTaskDefinitionResult' => {
          'taskDefinition' => {
            'revision'             => Integer,
            'taskDefinitionArn'    => String,
            'family'               => String,
            'containerDefinitions' => [Hash],
            'volumes'              => Fog::Nullable::Array
          }
        }
      })
      LIST_TASK_DEFINITIONS = BASIC.merge({
        'ListTaskDefinitionsResult' => {
          'taskDefinitionArns' => [String]
        }
      })
      DESCRIBE_TASK_DEFINITION = BASIC.merge({
        'DescribeTaskDefinitionResult' => {
          'taskDefinition' => {
            'revision'             => Integer,
            'taskDefinitionArn'    => String,
            'family'               => String,
            'containerDefinitions' => [Hash],
            'volumes'              => Fog::Nullable::Array
          }
        }
      })
      DEREGISTER_TASK_DEFINITION = BASIC.merge({
        'DeregisterTaskDefinitionResult' => {
          'taskDefinition' => {
            'revision'             => Integer,
            'taskDefinitionArn'    => String,
            'family'               => String,
            'containerDefinitions' => [Hash],
            'volumes'              => Fog::Nullable::Array
          }
        }
      })
      LIST_TASK_DEFINITION_FAMILIES = BASIC.merge({
        'ListTaskDefinitionFamiliesResult' => {
          'families' => [String]
        }
      })
      CREATE_SERVICE = BASIC.merge({
        'CreateServiceResult' => {
          'service' => {
            'events'         => [Fog::Nullable::Hash],
            'serviceName'    => String,
            'serviceArn'     => String,
            'taskDefinition' => String,
            'clusterArn'     => String,
            'status'         => String,
            'roleArn'        => Fog::Nullable::String,
            'loadBalancers'  => [Fog::Nullable::Hash],
            'deployments'    => [Fog::Nullable::Hash],
            'desiredCount'   => Integer,
            'pendingCount'   => Integer,
            'runningCount'   => Integer
          }
        }
      })
      DELETE_SERVICE = BASIC.merge({
        'DeleteServiceResult' => {
          'service' => {
            'events'         => [Fog::Nullable::Hash],
            'serviceName'    => String,
            'serviceArn'     => String,
            'taskDefinition' => String,
            'clusterArn'     => String,
            'status'         => String,
            'roleArn'        => Fog::Nullable::String,
            'loadBalancers'  => [Fog::Nullable::Hash],
            'deployments'    => [Fog::Nullable::Hash],
            'desiredCount'   => Integer,
            'pendingCount'   => Integer,
            'runningCount'   => Integer
          }
        }
      })
      DESCRIBE_SERVICES = BASIC.merge({
        'DescribeServicesResult' => {
          'failures' => [Fog::Nullable::Hash],
          'services' => [{
            'events'         => [Fog::Nullable::Hash],
            'serviceName'    => String,
            'serviceArn'     => String,
            'taskDefinition' => String,
            'clusterArn'     => String,
            'status'         => String,
            'roleArn'        => Fog::Nullable::String,
            'loadBalancers'  => [Fog::Nullable::Hash],
            'deployments'    => [Fog::Nullable::Hash],
            'desiredCount'   => Integer,
            'pendingCount'   => Integer,
            'runningCount'   => Integer
          }]
        }
      })
      LIST_SERVICES = BASIC.merge({
        'ListServicesResult' => {
          'serviceArns'  => [Fog::Nullable::String],
          'nextToken' => Fog::Nullable::String
        }
      })
      UPDATE_SERVICE = BASIC.merge({
        'UpdateServiceResult' => {
          'service' => {
            'events'         => [Fog::Nullable::Hash],
            'serviceName'    => String,
            'serviceArn'     => String,
            'taskDefinition' => String,
            'clusterArn'     => String,
            'status'         => String,
            'roleArn'        => Fog::Nullable::String,
            'loadBalancers'  => [Fog::Nullable::Hash],
            'deployments'    => [Fog::Nullable::Hash],
            'desiredCount'   => Integer,
            'pendingCount'   => Integer,
            'runningCount'   => Integer
          }
        }
      })
      LIST_CONTAINER_INSTANCES = BASIC.merge({
        'ListContainerInstancesResult' => {
          'containerInstanceArns' => [Fog::Nullable::String]
        }
      })
      DESCRIBE_CONTAINER_INSTANCES = BASIC.merge({
        'DescribeContainerInstancesResult' => {
          'containerInstances' => [{
            'remainingResources'   => [Hash],
            'agentConnected'       => Fog::Boolean,
            'runningTasksCount'    => Integer,
            'status'               => String,
            'registeredResources'  => [Hash],
            'containerInstanceArn' => String,
            'pendingTasksCount'    => Integer,
            'ec2InstanceId'        => String
          }],
          'failures' => [Fog::Nullable::Hash],
        }
      })
      DEREGISTER_CONTAINER_INSTANCE = BASIC.merge({
        'DeregisterContainerInstanceResult' => {
          'containerInstance' => {
            'remainingResources'   => [Hash],
            'agentConnected'       => Fog::Boolean,
            'runningTasksCount'    => Integer,
            'status'               => String,
            'registeredResources'  => [Hash],
            'containerInstanceArn' => String,
            'pendingTasksCount'    => Integer,
            'ec2InstanceId'        => String
          }
        }
      })
      LIST_TASKS = BASIC.merge({
        'ListTasksResult' => {
          'taskArns' => [Fog::Nullable::String]
        }
      })
      DESCRIBE_TASKS = BASIC.merge({
        'DescribeTasksResult' => {
          'failures' => [Fog::Nullable::Hash],
          'tasks' => [
            {
              'clusterArn'           => String,
              'containers'           => Array,
              'overrides'            => Fog::Nullable::Hash,
              'startedBy'            => Fog::Nullable::String,
              'desiredStatus'        => String,
              'taskArn'              => String,
              'containerInstanceArn' => String,
              'lastStatus'           => String,
              'taskDefinitionArn'    => String
            }
          ]
        }
      })
      RUN_TASK = BASIC.merge({
        'RunTaskResult' => {
          'failures' => [Fog::Nullable::Hash],
          'tasks' => [
            {
              'clusterArn'           => String,
              'containers'           => [Hash],
              'overrides'            => Fog::Nullable::Hash,
              'desiredStatus'        => String,
              'taskArn'              => String,
              'containerInstanceArn' => String,
              'lastStatus'           => String,
              'taskDefinitionArn'    => String
            }
          ]
        }
      })
      STOP_TASK = BASIC.merge({
        'StopTaskResult' => {
          'task' => {
            'clusterArn'           => String,
            'containers'           => [Hash],
            'overrides'            => Fog::Nullable::Hash,
            'desiredStatus'        => String,
            'taskArn'              => String,
            'startedBy'            => Fog::Nullable::String,
            'containerInstanceArn' => String,
            'lastStatus'           => String,
            'taskDefinitionArn'    => String
          }
        }
      })
      START_TASK = BASIC.merge({
        'StartTaskResult' => {
          'failures' => [Fog::Nullable::Hash],
          'tasks' => [
            {
              'clusterArn'           => String,
              'containers'           => [Hash],
              'overrides'            => Fog::Nullable::Hash,
              'desiredStatus'        => String,
              'taskArn'              => String,
              'containerInstanceArn' => String,
              'lastStatus'           => String,
              'taskDefinitionArn'    => String
            }
          ]
        }
      })
    end
    module Samples
      TASK_DEFINITION_1 = File.dirname(__FILE__) + '/sample_task_definition1.json'
    end
  end
end
