class AWS
  module ELBV2
    module Formats
      BASIC = {
        'ResponseMetadata' => {'RequestId' => String}
      }

      LOAD_BALANCER = {
        "AvailabilityZones" => [{
          "SubnetId" => String, "ZoneName" => String,
          "LoadBalancerAddresses" => [Fog::Nullable::Hash]
        }],
        "LoadBalancerArn" => String,
        "DNSName" => String,
        "CreatedTime" => Time,
        "LoadBalancerName" => String,
        "VpcId" => String,
        "CanonicalHostedZoneId" => String,
        "Scheme" => String,
        "Type" => String,
        "State" => {"Code" => String},
        "SecurityGroups" => [Fog::Nullable::String]
      }

      DESCRIBE_LOAD_BALANCERS = BASIC.merge({
        'DescribeLoadBalancersResult' => {'LoadBalancers' => [LOAD_BALANCER], 'NextMarker' => Fog::Nullable::String}
      })

      CREATE_LOAD_BALANCER = BASIC.merge({
        'CreateLoadBalancerResult' => {'LoadBalancers' => [LOAD_BALANCER]}
      })

      LISTENER_DEFAULT_ACTIONS = [{
        "Type" => String,
        "Order" => String,
        "TargetGroupArn" => String,
        "RedirectConfig" => Fog::Nullable::Hash,
        "ForwardConfig" => Fog::Nullable::Hash,
        "FixedResponseConfig" => Fog::Nullable::Hash
      }]

      LISTENER = {
        "LoadBalancerArn" => String,
        "Protocol" => String,
        "Port" => String,
        "ListenerArn" => String,
        "SslPolicy" => String,
        "DefaultActions" => LISTENER_DEFAULT_ACTIONS,
        "Certificates" => [{"CertificateArn" => String}]
      }

      DESCRIBE_LISTENERS = BASIC.merge({
        'DescribeListenersResult' => {'Listeners' => [LISTENER], 'NextMarker' => Fog::Nullable::String}
      })

      TAG_DESCRIPTIONS = [{
        "Tags" => Hash,
        "ResourceArn" => String
      }]

      DESCRIBE_TAGS = BASIC.merge({
        'DescribeTagsResult' => {'TagDescriptions' => TAG_DESCRIPTIONS}
      })
    end
  end
end
