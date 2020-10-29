Shindo.tests("Fog::Compute[:aws] | vpc", ['aws']) do

  model_tests(Fog::Compute[:aws].vpcs, {:cidr_block => '10.0.10.0/28'}, true) do
    tests("#enable_classic_link") do
      returns(false) { @instance.classic_link_enabled? }
      returns(true)  { @instance.enable_classic_link }
      returns(true)  { @instance.classic_link_enabled? }
    end

    tests("#disable_classic_link") do
      returns(true)  { @instance.disable_classic_link }
      returns(false) { @instance.classic_link_enabled? }
    end

    tests("#enable_classic_link_dns") do
      returns(false) { @instance.classic_link_dns_enabled? }
      returns(true)  { @instance.enable_classic_link_dns }
      returns(true)  { @instance.classic_link_dns_enabled? }
    end

    tests("#disable_classic_link") do
      returns(true)  { @instance.disable_classic_link_dns }
      returns(false) { @instance.classic_link_dns_enabled? }
    end
  end
end
