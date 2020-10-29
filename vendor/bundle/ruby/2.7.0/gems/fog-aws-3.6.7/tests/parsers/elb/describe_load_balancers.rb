require 'fog/xml'
require 'fog/aws/parsers/elb/describe_load_balancers'

DESCRIBE_LOAD_BALANCERS_RESULT = <<-EOF
<DescribeLoadBalancersResponse
xmlns="http://elasticloadbalancing.amazonaws.com/doc/2012-06-01/">
  <DescribeLoadBalancersResult>
    <LoadBalancerDescriptions>
      <member>
        <SecurityGroups/>
        <CreatedTime>2013-08-01T15:47:20.930Z</CreatedTime>
        <LoadBalancerName>fog-test-elb</LoadBalancerName>
        <HealthCheck>
          <Interval>30</Interval>
          <Target>TCP:80</Target>
          <HealthyThreshold>10</HealthyThreshold>
          <Timeout>5</Timeout>
          <UnhealthyThreshold>2</UnhealthyThreshold>
        </HealthCheck>
        <ListenerDescriptions>
          <member>
            <PolicyNames/>
            <Listener>
              <Protocol>HTTP</Protocol>
              <LoadBalancerPort>80</LoadBalancerPort>
              <InstanceProtocol>HTTP</InstanceProtocol>
              <InstancePort>80</InstancePort>
            </Listener>
          </member>
        </ListenerDescriptions>
        <Instances/>
        <Policies>
          <AppCookieStickinessPolicies/>
          <OtherPolicies/>
          <LBCookieStickinessPolicies/>
        </Policies>
        <AvailabilityZones>
          <member>us-east-1a</member>
        </AvailabilityZones>
        <CanonicalHostedZoneName>fog-test-elb-1965660309.us-east-1.elb.amazonaws.com</CanonicalHostedZoneName>
        <CanonicalHostedZoneNameID>Z3DZXE0Q79N41H</CanonicalHostedZoneNameID>
        <Scheme>internet-facing</Scheme>
        <SourceSecurityGroup>
          <OwnerAlias>amazon-elb</OwnerAlias>
          <GroupName>amazon-elb-sg</GroupName>
        </SourceSecurityGroup>
        <DNSName>fog-test-elb-1965660309.us-east-1.elb.amazonaws.com</DNSName>
        <BackendServerDescriptions/>
        <Subnets/>
      </member>
    </LoadBalancerDescriptions>
  </DescribeLoadBalancersResult>
  <ResponseMetadata>
    <RequestId>a6ea2117-fac1-11e2-abd3-1740ab4ef14e</RequestId>
  </ResponseMetadata>
</DescribeLoadBalancersResponse>
EOF

Shindo.tests('AWS::ELB | parsers | describe_load_balancers', %w[aws elb parser]) do
  tests('parses the xml').formats(AWS::ELB::Formats::DESCRIBE_LOAD_BALANCERS) do
    parser = Nokogiri::XML::SAX::Parser.new(Fog::Parsers::AWS::ELB::DescribeLoadBalancers.new)
    parser.parse(DESCRIBE_LOAD_BALANCERS_RESULT)
    parser.document.response
  end
end
