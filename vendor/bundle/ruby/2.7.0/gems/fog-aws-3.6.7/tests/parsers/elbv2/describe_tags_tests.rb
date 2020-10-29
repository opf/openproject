require 'fog/xml'
require 'fog/aws/parsers/elbv2/describe_tags'

DESCRIBE_TAGS_RESULT = <<-EOF
<DescribeTagsResponse xmlns="http://elasticloadbalancing.amazonaws.com/doc/2015-12-01/">
  <DescribeTagsResult>
    <TagDescriptions>
      <member>
        <ResourceArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188</ResourceArn>
        <Tags>
          <member>
            <Value>lima</Value>
            <Key>project</Key>
          </member>
          <member>
            <Value>digital-media</Value>
            <Key>department</Key>
          </member>
        </Tags>
      </member>
    </TagDescriptions>
  </DescribeTagsResult>
  <ResponseMetadata>
    <RequestId>34f144db-f2d9-11e5-a53c-67205c0d10fd</RequestId> 
  </ResponseMetadata>
</DescribeTagsResponse>
EOF

Shindo.tests('AWS::ELBV2 | parsers | describe_tags', %w[aws elb parser]) do
  tests('parses the xml').formats(AWS::ELBV2::Formats::DESCRIBE_TAGS) do
    parser = Nokogiri::XML::SAX::Parser.new(Fog::Parsers::AWS::ELBV2::DescribeTags.new)
    parser.parse(DESCRIBE_TAGS_RESULT)
    parser.document.response
  end
end
