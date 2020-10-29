require 'fog/xml'
require 'fog/aws/parsers/compute/describe_images'

DESCRIBE_IMAGES_RESULT = <<-EOF
<DescribeImagesResponse xmlns="http://ec2.amazonaws.com/doc/2016-11-15/">
    <requestId>180a8433-ade0-4a6c-b35b-107897579572</requestId>
    <imagesSet>
        <item>
            <imageId>aki-02486376</imageId>
            <imageLocation>ec2-public-images-eu/vmlinuz-2.6.21-2.fc8xen-ec2-v1.0.i386.aki.manifest.xml</imageLocation>
            <imageState>available</imageState>
            <imageOwnerId>206029621532</imageOwnerId>
            <creationDate/>
            <isPublic>true</isPublic>
            <architecture>i386</architecture>
            <imageType>kernel</imageType>
            <imageOwnerAlias>amazon</imageOwnerAlias>
            <rootDeviceType>instance-store</rootDeviceType>
            <blockDeviceMapping/>
            <virtualizationType>paravirtual</virtualizationType>
            <hypervisor>xen</hypervisor>
        </item>
    </imagesSet>
</DescribeImagesResponse>
EOF

Shindo.tests('AWS::Compute | parsers | describe_images', %w[compute aws parser]) do
  tests('parses the xml').formats(AWS::Compute::Formats::DESCRIBE_IMAGES) do
    parser = Nokogiri::XML::SAX::Parser.new(Fog::Parsers::AWS::Compute::DescribeImages.new)
    parser.parse(DESCRIBE_IMAGES_RESULT)
    parser.document.response
  end
end
