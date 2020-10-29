require 'fog/xml'
require 'fog/aws/parsers/elbv2/describe_load_balancers'

DESCRIBE_LOAD_BALANCERS_RESULT = <<-EOF
<DescribeLoadBalancersResponse xmlns="http://elasticloadbalancing.amazonaws.com/doc/2015-12-01/">
  <DescribeLoadBalancersResult>
    <LoadBalancers>
      <member>
        <LoadBalancerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188</LoadBalancerArn>
        <Scheme>internet-facing</Scheme>
        <LoadBalancerName>my-load-balancer</LoadBalancerName>
        <VpcId>vpc-3ac0fb5f</VpcId>
        <CanonicalHostedZoneId>Z2P70J7EXAMPLE</CanonicalHostedZoneId>
        <CreatedTime>2016-03-25T21:26:12.920Z</CreatedTime>
        <AvailabilityZones>
          <member>
            <SubnetId>subnet-8360a9e7</SubnetId>
            <ZoneName>us-west-2a</ZoneName>
          </member>
          <member>
            <SubnetId>subnet-b7d581c0</SubnetId>
            <ZoneName>us-west-2b</ZoneName>
            <LoadBalancerAddresses>
              <member>
                <IpAddress>127.0.0.1</IpAddress>
                <AllocationId>eipalloc-1c2ab192c131q2377</AllocationId>
              </member>
            </LoadBalancerAddresses>
          </member>
        </AvailabilityZones>
        <SecurityGroups>
          <member>sg-5943793c</member>
        </SecurityGroups>
        <DNSName>my-load-balancer-424835706.us-west-2.elb.amazonaws.com</DNSName>
        <State>
          <Code>active</Code>
        </State>
        <Type>application</Type>
      </member>
    </LoadBalancers>
  </DescribeLoadBalancersResult>
  <ResponseMetadata>
    <RequestId>6581c0ac-f39f-11e5-bb98-57195a6eb84a</RequestId>
  </ResponseMetadata>
</DescribeLoadBalancersResponse>
EOF

Shindo.tests('AWS::ELBV2 | parsers | describe_load_balancers', %w[aws elb parser]) do
  tests('parses the xml').formats(AWS::ELBV2::Formats::DESCRIBE_LOAD_BALANCERS) do
    parser = Nokogiri::XML::SAX::Parser.new(Fog::Parsers::AWS::ELBV2::DescribeLoadBalancers.new)
    parser.parse(DESCRIBE_LOAD_BALANCERS_RESULT)
    parser.document.response
  end
end
