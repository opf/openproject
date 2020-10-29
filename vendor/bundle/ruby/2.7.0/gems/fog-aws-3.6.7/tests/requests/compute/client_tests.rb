Shindo.tests('Fog::Compute[:aws] | account tests', ['aws']) do
  if Fog.mocking?
    tests('check for vpc') do
      tests('supports both vpc and ec2 in compatibility mode').succeeds do
        client = Fog::Compute[:aws]
        client.enable_ec2_classic
        data = Fog::Compute[:aws].describe_account_attributes.body
        data['accountAttributeSet'].any? { |s| [*s["values"]].include?("VPC") && [*s["values"]].include?("EC2") }
      end
      tests('supports VPC in vpc mode').succeeds do
        client = Fog::Compute[:aws]
        client.enable_ec2_classic
        data = Fog::Compute[:aws].describe_account_attributes.body
        data['accountAttributeSet'].any? { |s| [*s["values"]].include?("VPC") }
      end

      tests('does not support VPC and EC2 in vpc mode').succeeds do
        client = Fog::Compute[:aws]
        client.disable_ec2_classic
        data = Fog::Compute[:aws].describe_account_attributes.body
        !data['accountAttributeSet'].any? { |s| [*s["values"]].include?("VPC") && [*s["values"]].include?("EC2") }
      end
    end
  end
end
