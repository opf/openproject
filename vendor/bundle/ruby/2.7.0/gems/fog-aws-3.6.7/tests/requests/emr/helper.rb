class AWS
  module EMR
    module Formats
      BASIC = {
        'RequestId' => String
      }

      RUN_JOB_FLOW = BASIC.merge({
        'JobFlowId' => String
      })

      ADD_INSTANCE_GROUPS = {
        'JobFlowId' => String,
        'InstanceGroupIds' => Array
      }

      SIMPLE_DESCRIBE_JOB_FLOW = {
        'JobFlows' => [{
          'Name' => String,
          'BootstrapActions' => {
            'ScriptBootstrapActionConfig' => {
              'Args' => Array
            }
          },
          'ExecutionStatusDetail' => {
            'CreationDateTime' => String,
            'State' => String,
            'LastStateChangeReason' => String
          },
          'Steps' => [{
            'ActionOnFailure' => String,
            'Name' => String,
            'StepConfig' => {
              'HadoopJarStepConfig' => {
                'MainClass' => String,
                'Jar' => String,
                'Args' => Array,
                'Properties' => Array
              }
            },
            'ExecutionStatusDetail' => {
              'CreationDateTime' => String,
              'State' => String
            }
          }],
          'JobFlowId' => String,
          'Instances' => {
            'InstanceCount' => String,
            'NormalizedInstanceHours' => String,
            'KeepJobFlowAliveWhenNoSteps' => String,
            'Placement' => {
              'AvailabilityZone' => String
            },
            'MasterInstanceType' => String,
            'SlaveInstanceType' => String,
            'InstanceGroups' => Array,
            'TerminationProtected' => String,
            'HadoopVersion' => String
          }
        }]
      }

      JOB_FLOW_WITHOUT_CHANGE = {
        'JobFlows' => [{
          'Name' => String,
          'BootstrapActions' => {
            'ScriptBootstrapActionConfig' => {
              'Args' => Array
            }
          },
          'ExecutionStatusDetail' => {
            'CreationDateTime' => String,
            'State' => String,
            'LastStateChangeReason' => NilClass
          },
          'Steps' => [{
            'ActionOnFailure' => String,
            'Name' => String,
            'StepConfig' => {
              'HadoopJarStepConfig' => {
                'MainClass' => String,
                'Jar' => String,
                'Args' => Array,
                'Properties' => Array
              }
            },
            'ExecutionStatusDetail' => {
              'CreationDateTime' => String,
              'State' => String
            }
          }],
          'JobFlowId' => String,
          'Instances' => {
            'InstanceCount' => String,
            'NormalizedInstanceHours' => String,
            'KeepJobFlowAliveWhenNoSteps' => String,
            'Placement' => {
              'AvailabilityZone' => String
            },
            'MasterInstanceType' => String,
            'SlaveInstanceType' => String,
            'InstanceGroups' => Array,
            'TerminationProtected' => String,
            'HadoopVersion' => String
          }
        }]
      }

      DESCRIBE_JOB_FLOW_WITH_INSTANCE_GROUPS = {
        'JobFlows' => [{
          'Name' => String,
          'BootstrapActions' => {
            'ScriptBootstrapActionConfig' => {
              'Args' => Array
            }
          },
          'ExecutionStatusDetail' => {
            'CreationDateTime' => String,
            'State' => String,
            'LastStateChangeReason' => NilClass
          },
          'Steps' => [{
            'ActionOnFailure' => String,
            'Name' => String,
            'StepConfig' => {
              'HadoopJarStepConfig' => {
                'MainClass' => String,
                'Jar' => String,
                'Args' => Array,
                'Properties' => Array
              }
            },
            'ExecutionStatusDetail' => {
              'CreationDateTime' => String,
              'State' => String
            }
          }],
          'JobFlowId' => String,
          'Instances' => {
            'InstanceCount' => String,
            'NormalizedInstanceHours' => String,
            'KeepJobFlowAliveWhenNoSteps' => String,
            'Placement' => {
              'AvailabilityZone' => String
            },
            'InstanceGroups' => [{
              'Name' => String,
              'InstanceRole' => String,
              'CreationDateTime' => String,
              'LastStateChangeReason' => nil,
              'InstanceGroupId' => String,
              'Market' => String,
              'InstanceType' => String,
              'State' => String,
              'InstanceRunningCount' => String,
              'InstanceRequestCount' => String
            }],
            'MasterInstanceType' => String,
            'SlaveInstanceType' => String,
            'TerminationProtected' => String,
            'HadoopVersion' => String
          }
        }]
      }
    end
  end
end
