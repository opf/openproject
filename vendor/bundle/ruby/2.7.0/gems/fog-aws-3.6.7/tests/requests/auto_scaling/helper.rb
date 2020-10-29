class AWS
  module AutoScaling
    module Formats
      BASIC = {
        'ResponseMetadata' => {'RequestId' => String}
      }

      PAGINATED = {
        'NextToken' => Fog::Nullable::String
      }

      ACTIVITY = {
        'ActivityId' => String,
        'AutoScalingGroupName' => String,
        'Cause' => Fog::Nullable::String,
        'Description' => String,
        'EndTime' => Time,
        'Progress' => Integer,
        'StartTime' => Time,
        'StatusCode' => String,
        'StatusMessage' => Fog::Nullable::String
      }

      ALARM = {
        'AlarmARN' => String,
        'AlarmName' => String
      }

      BLOCK_DEVICE_MAPPING = {
        'DeviceName' => String,
        'Ebs' => {'SnapshotId' => String, 'VolumeSize' => Integer},
        'VirtualName' => String
      }

      ENABLED_METRIC = {
        'Granularity' => Array,
        'Metric' => Array
      }

      INSTANCE = {
        'AvailabilityZone' => String,
        'HealthStatus' => String,
        'InstanceId' => String,
        'LaunchConfigurationName' => String,
        'LifecycleState' => String
      }

      NOTIFICATION_CONFIGURATION = {
        'AutoScalingGroupName' => String,
        'NotificationType' => String,
        'TopicARN' => String
      }

      SCHEDULED_UPDATE_GROUP_ACTION = {
        'AutoScalingGroupName' => String,
        'DesiredCapacity' => Integer,
        'EndTime' => Time,
        'MaxSize' => Integer,
        'MinSize' => Integer,
        'Recurrence' => String,
        'ScheduledActionARN' => String,
        'ScheduledActionName' => String,
        'StartTime' => Time,
      }

      PROCESS_TYPE = {
        'ProcessName' => String
      }

      SUSPENDED_PROCESS = PROCESS_TYPE.merge({
        'SuspensionReason' => String
      })

      TAG_DESCRIPTION = {
        'Key' => String,
        'PropagateAtLaunch' => Fog::Boolean,
        'ResourceId' => String,
        'ResourceType' => String,
        'Value' => Fog::Nullable::String
      }

      AUTO_SCALING_GROUP = {
        'AutoScalingGroupARN' => String,
        'AutoScalingGroupName' => String,
        'AvailabilityZones' => Array,
        'CreatedTime' => Time,
        'DefaultCooldown' => Integer,
        'DesiredCapacity' => Integer,
        'EnabledMetrics' => [ENABLED_METRIC],
        'HealthCheckGracePeriod' => Integer,
        'HealthCheckType' => String,
        'Instances' => [INSTANCE],
        'LaunchConfigurationName' => String,
        'LoadBalancerNames' => Array,
        'MaxSize' => Integer,
        'MinSize' => Integer,
        'PlacementGroup' => Fog::Nullable::String,
        'Status' => Fog::Nullable::String,
        'SuspendedProcesses' => [SUSPENDED_PROCESS],
        'Tags' => [TAG_DESCRIPTION],
        'TargetGroupARNs' => Array,
        'TerminationPolicies' => [String],
        'VPCZoneIdentifier' => Fog::Nullable::String
      }

      AUTO_SCALING_INSTANCE_DETAILS = INSTANCE.merge({
        'AutoScalingGroupName' => String
      })

      LAUNCH_CONFIGURATION = {
        'BlockDeviceMappings' => [BLOCK_DEVICE_MAPPING],
        'CreatedTime' => Time,
        'ImageId' => String,
        'InstanceMonitoring' => {'Enabled' => Fog::Boolean},
        'InstanceType' => String,
        'KernelId' => Fog::Nullable::String,
        'KeyName' => Fog::Nullable::String,
        'LaunchConfigurationARN' => String,
        'LaunchConfigurationName' => String,
        'RamdiskId' => Fog::Nullable::String,
        'SpotPrice' => Fog::Nullable::String,
        'SecurityGroups' => Array,
        'UserData' => Fog::Nullable::String
      }

      SCALING_POLICY = {
        'AdjustmentType' => String,
        'Alarms' => [ALARM],
        'AutoScalingGroupName' => String,
        'Cooldown' => Integer,
        'MinAdjustmentStep' => Integer,
        'PolicyARN' => String,
        'PolicyName' => String,
        'ScalingAdjustment' => Integer
      }

      DESCRIBE_ADJUSTMENT_TYPES = BASIC.merge({
        'DescribeAdjustmentTypesResult' => {
          'AdjustmentTypes' => [{'AdjustmentType' => String}]
        }
      })

      DESCRIBE_AUTO_SCALING_GROUPS = BASIC.merge({
        'DescribeAutoScalingGroupsResult' => PAGINATED.merge({
          'AutoScalingGroups' => [AUTO_SCALING_GROUP],
        })
      })

      DESCRIBE_AUTO_SCALING_INSTANCES = BASIC.merge({
        'DescribeAutoScalingInstancesResult' => PAGINATED.merge({
          'AutoScalingInstances' => [AUTO_SCALING_INSTANCE_DETAILS],
        })
      })

      DESCRIBE_AUTO_SCALING_NOTIFICATION_TYPES = BASIC.merge({
        'DescribeAutoScalingNotificationTypesResult' => {
          'AutoScalingNotificationTypes' => [String]
        }
      })

      DESCRIBE_LAUNCH_CONFIGURATIONS = BASIC.merge({
        'DescribeLaunchConfigurationsResult' => PAGINATED.merge({
          'LaunchConfigurations' => [LAUNCH_CONFIGURATION],
        })
      })

      DESCRIBE_METRIC_COLLECTION_TYPES = BASIC.merge({
        'DescribeMetricCollectionTypesResult' => {
          'Granularities' => [{'Granularity' => String}],
          'Metrics' => [{'Metric' => String}]
        }
      })

      DESCRIBE_NOTIFICATION_CONFIGURATIONS = BASIC.merge({
        'DescribeNotificationConfigurationsResult' => PAGINATED.merge({
          'NotificationConfigurations' => [NOTIFICATION_CONFIGURATION]
        })
      })

      DESCRIBE_POLICIES = BASIC.merge({
        'DescribePoliciesResult' => PAGINATED.merge({
          'ScalingPolicies' => [SCALING_POLICY]
        })
      })

      DESCRIBE_SCALING_ACTIVITIES = BASIC.merge({
        'DescribeScalingActivitiesResult' => PAGINATED.merge({
          'Activities' => [ACTIVITY],
        })
      })

      DESCRIBE_SCALING_PROCESS_TYPES = BASIC.merge({
        'DescribeScalingProcessTypesResult' => {
          'Processes' => [PROCESS_TYPE]
        }
      })

      DESCRIBE_SCHEDULED_ACTIONS = BASIC.merge({
        'DescribeScheduledActionsResult' => PAGINATED.merge({
          'ScheduledUpdateGroupActions' => [SCHEDULED_UPDATE_GROUP_ACTION]
        })
      })

      DESCRIBE_TAGS = BASIC.merge({
        'DescribeTagsResult' => PAGINATED.merge({
          'Tags' => [TAG_DESCRIPTION]
        })
      })

      DESCRIBE_TERMINATION_POLICY_TYPES = BASIC.merge({
        'DescribeTerminationPolicyTypesResult' => {
          'TerminationPolicyTypes' => [String]
        }
      })

      PUT_SCALING_POLICY = BASIC.merge({
        'PutScalingPolicyResult' => {
          'PolicyARN' => String
        }
      })

      TERMINATE_INSTANCE_IN_AUTO_SCALING_GROUP = BASIC.merge({
        'TerminateInstanceInAutoScalingGroupResult' => {
          'Activity' => [ACTIVITY]
        }
      })
    end
  end
end
