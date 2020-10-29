Shindo.tests("AWS::ELB | tagging", ['aws', 'elb']) do
  @elb5 = Fog::AWS[:elb].load_balancers.create(:id => "fog-test-elb-tagging")
  tags1 = {'key1' => 'val1'}
  tags2 = {'key2' => 'val2'}
  
  tests "add and remove tags from an ELB" do
    returns({})                 { @elb5.tags }
    returns(tags1)              { @elb5.add_tags tags1 }
    returns(tags1.merge tags2)  { @elb5.add_tags tags2 }
    returns(tags2)              { @elb5.remove_tags tags1.keys  }
    returns(tags2)              { @elb5.tags }
    
    @elb5.destroy
  end
end
