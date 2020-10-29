require 'fog/xml'
require 'fog/aws/parsers/elbv2/create_load_balancer'

CREATE_LOAD_BALANCER_RESULT = <<-EOF
<CreateLoadBalancerResponse xmlns="http://elasticloadbalancing.amazonaws.com/doc/2015-12-01/">
  <CreateLoadBalancerResult>
    <LoadBalancers>
      <member>
        <LoadBalancerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-internal-load-balancer/50dc6c495c0c9188</LoadBalancerArn>
        <Scheme>internet-facing</Scheme>
        <LoadBalancerName>my-load-balancer</LoadBalancerName>
        <VpcId>vpc-3ac0fb5f</VpcId>
        <CanonicalHostedZoneId>Z2P70J7EXAMPLE</CanonicalHostedZoneId>
        <CreatedTime>2016-03-25T21:29:48.850Z</CreatedTime>
        <AvailabilityZones>
          <member>
            <SubnetId>subnet-8360a9e7</SubnetId>
            <ZoneName>us-west-2a</ZoneName>
          </member>
          <member>
            <SubnetId>subnet-b7d581c0</SubnetId>
            <ZoneName>us-west-2b</ZoneName>
          </member>
        </AvailabilityZones>
        <SecurityGroups>
          <member>sg-5943793c</member>
        </SecurityGroups>
        <DNSName>my-load-balancer-424835706.us-west-2.elb.amazonaws.com</DNSName>
        <State>
          <Code>provisioning</Code>
        </State>
        <Type>application</Type>
      </member>
    </LoadBalancers>
  </CreateLoadBalancerResult>
  <ResponseMetadata>
    <RequestId>32d531b2-f2d0-11e5-9192-3fff33344cfa</RequestId>
  </ResponseMetadata>
</CreateLoadBalancerResponse>
EOF

Shindo.tests('AWS::ELBV2 | parsers | create_load_balancer', %w[aws elb parser]) do
  tests('parses the xml').formats(AWS::ELBV2::Formats::CREATE_LOAD_BALANCER) do
    parser = Nokogiri::XML::SAX::Parser.new(Fog::Parsers::AWS::ELBV2::CreateLoadBalancer.new)
    parser.parse(CREATE_LOAD_BALANCER_RESULT)
    parser.document.response
  end
end
