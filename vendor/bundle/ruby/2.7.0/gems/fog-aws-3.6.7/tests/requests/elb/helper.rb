class AWS
  module ELB
    module Formats
      BASIC = {
        'ResponseMetadata' => {'RequestId' => String}
      }

      LOAD_BALANCER = {
        "AvailabilityZones" => Array,
        "BackendServerDescriptions" => Array,
        "CanonicalHostedZoneName" => String,
        "CanonicalHostedZoneNameID" => String,
        "CreatedTime" => Time,
        "DNSName" => String,
        "HealthCheck" => {"HealthyThreshold" => Integer, "Timeout" => Integer, "UnhealthyThreshold" => Integer, "Interval" => Integer, "Target" => String},
        "Instances" => Array,
        "ListenerDescriptions" => [{
          'PolicyNames' => Array,
          'Listener' => {
            'InstancePort' => Integer,
            'InstanceProtocol' => String,
            'LoadBalancerPort' => Integer,
            'Protocol' => String,
            'SSLCertificateId' => Fog::Nullable::String
          }
        }],
        "LoadBalancerName" => String,
        "Policies" => {"LBCookieStickinessPolicies" => Array, "AppCookieStickinessPolicies" => Array, "OtherPolicies" => Array},
        "Scheme" => String,
        "SecurityGroups" => [Fog::Nullable::String],
        "SourceSecurityGroup" => {"GroupName" => String, "OwnerAlias" => String},
        "Subnets" => [Fog::Nullable::String]
      }

      CREATE_LOAD_BALANCER = BASIC.merge({
        'CreateLoadBalancerResult' => { 'DNSName' => String }
      })

      DESCRIBE_LOAD_BALANCERS = BASIC.merge({
        'DescribeLoadBalancersResult' => {'LoadBalancerDescriptions' => [LOAD_BALANCER], 'NextMarker' => Fog::Nullable::String}
      })

      POLICY_ATTRIBUTE_DESCRIPTION = {
        "AttributeName" => String,
        "AttributeValue" => String
      }

      POLICY = {
        "PolicyAttributeDescriptions" => [POLICY_ATTRIBUTE_DESCRIPTION],
        "PolicyName" => String,
        "PolicyTypeName" => String
      }

      DESCRIBE_LOAD_BALANCER_POLICIES = BASIC.merge({
        'DescribeLoadBalancerPoliciesResult' => { 'PolicyDescriptions' => [POLICY] }
      })

      POLICY_ATTRIBUTE_TYPE_DESCRIPTION = {
        "AttributeName" => String,
        "AttributeType" => String,
        "Cardinality" => String,
        "DefaultValue" => String,
        "Description" => String
      }

      POLICY_TYPE = {
        "Description" => String,
        "PolicyAttributeTypeDescriptions" => [POLICY_ATTRIBUTE_TYPE_DESCRIPTION],
        "PolicyTypeName" => String
      }

      DESCRIBE_LOAD_BALANCER_POLICY_TYPES = BASIC.merge({
        'DescribeLoadBalancerPolicyTypesResult' => {'PolicyTypeDescriptions' => [POLICY_TYPE] }
      })

      CONFIGURE_HEALTH_CHECK = BASIC.merge({
        'ConfigureHealthCheckResult' => {'HealthCheck' => {
        'Target' => String,
        'Interval' => Integer,
        'Timeout' => Integer,
        'UnhealthyThreshold' => Integer,
        'HealthyThreshold' => Integer
      }}
      })

      DELETE_LOAD_BALANCER = BASIC.merge({
        'DeleteLoadBalancerResult' =>  NilClass
      })
    end
  end
end
