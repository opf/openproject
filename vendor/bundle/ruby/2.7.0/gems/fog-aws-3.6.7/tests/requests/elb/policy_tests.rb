Shindo.tests('AWS::ELB | policy_tests', ['aws', 'elb']) do
  @load_balancer_id = 'fog-test-policies'

  tests('success') do
    listeners = [{'LoadBalancerPort' => 80, 'InstancePort' => 80, 'Protocol' => 'HTTP'}]
    Fog::AWS[:elb].create_load_balancer(['us-east-1a'], @load_balancer_id, listeners)

    tests("#describe_load_balancer_policy_types").formats(AWS::ELB::Formats::DESCRIBE_LOAD_BALANCER_POLICY_TYPES) do
      @policy_types = Fog::AWS[:elb].describe_load_balancer_policy_types.body
    end

    tests("#create_app_cookie_stickiness_policy").formats(AWS::ELB::Formats::BASIC) do
      cookie, policy = 'fog-app-cookie', 'fog-app-policy'
      Fog::AWS[:elb].create_app_cookie_stickiness_policy(@load_balancer_id, policy, cookie).body
    end

    tests("#create_lb_cookie_stickiness_policy with expiry").formats(AWS::ELB::Formats::BASIC) do
      policy = 'fog-lb-expiry'
      expiry = 300
      Fog::AWS[:elb].create_lb_cookie_stickiness_policy(@load_balancer_id, policy, expiry).body
    end

    tests("#create_lb_cookie_stickiness_policy without expiry").formats(AWS::ELB::Formats::BASIC) do
      policy = 'fog-lb-no-expiry'
      Fog::AWS[:elb].create_lb_cookie_stickiness_policy(@load_balancer_id, policy).body
    end

    tests("#create_load_balancer_policy").formats(AWS::ELB::Formats::BASIC) do
      policy = 'fog-policy'
      Fog::AWS[:elb].create_load_balancer_policy(@load_balancer_id, policy, 'PublicKeyPolicyType', {'PublicKey' => AWS::IAM::SERVER_CERT_PUBLIC_KEY}).body
    end

    tests("#describe_load_balancer_policies") do
      body = Fog::AWS[:elb].describe_load_balancer_policies(@load_balancer_id).body
      formats(AWS::ELB::Formats::DESCRIBE_LOAD_BALANCER_POLICIES) { body }

      # Check the result of each policy by name
      returns({
                "PolicyAttributeDescriptions"=>[{
                                                  "AttributeName"=>"CookieName",
                                                  "AttributeValue"=>"fog-app-cookie"
                                                }],
                "PolicyName"=>"fog-app-policy",
                "PolicyTypeName"=>"AppCookieStickinessPolicyType"
              }) do
        body["DescribeLoadBalancerPoliciesResult"]["PolicyDescriptions"].find{|e| e['PolicyName'] == 'fog-app-policy' }
      end

      returns({
                "PolicyAttributeDescriptions"=>[{
                                                  "AttributeName"=>"CookieExpirationPeriod",
                                                  "AttributeValue"=>"300"
                                                }],
                "PolicyName"=>"fog-lb-expiry",
                "PolicyTypeName"=>"LBCookieStickinessPolicyType"
              }) do
        body["DescribeLoadBalancerPoliciesResult"]["PolicyDescriptions"].find{|e| e['PolicyName'] == 'fog-lb-expiry' }
      end

      returns({
                "PolicyAttributeDescriptions"=>[{
                                                  "AttributeName"=>"CookieExpirationPeriod",
                                                  "AttributeValue"=>"0"
                                                }],
                "PolicyName"=>"fog-lb-no-expiry",
                "PolicyTypeName"=>"LBCookieStickinessPolicyType"
              }) do
        body["DescribeLoadBalancerPoliciesResult"]["PolicyDescriptions"].find{|e| e['PolicyName'] == 'fog-lb-no-expiry' }
      end

      returns({
                "PolicyAttributeDescriptions"=>[{
                                                  "AttributeName"=>"PublicKey",
                                                  "AttributeValue"=> AWS::IAM::SERVER_CERT_PUBLIC_KEY
                                                }],
                "PolicyName"=>"fog-policy",
                "PolicyTypeName"=>"PublicKeyPolicyType"
              }) do
        body["DescribeLoadBalancerPoliciesResult"]["PolicyDescriptions"].find{|e| e['PolicyName'] == 'fog-policy' }
      end
    end

    tests("#describe_load_balancer includes all policies") do
      lb = Fog::AWS[:elb].describe_load_balancers("LoadBalancerNames" => [@load_balancer_id]).body["DescribeLoadBalancersResult"]["LoadBalancerDescriptions"].first
      returns([
               {"PolicyName"=>"fog-app-policy", "CookieName"=>"fog-app-cookie"}
              ]) { lb["Policies"]["AppCookieStickinessPolicies"] }

      returns([
               {"PolicyName"=>"fog-lb-expiry", "CookieExpirationPeriod"=> 300}
              ]) { lb["Policies"]["LBCookieStickinessPolicies"].select{|e| e["PolicyName"] == "fog-lb-expiry"} }

      returns([
               {"PolicyName" => "fog-lb-no-expiry"}
              ]) { lb["Policies"]["LBCookieStickinessPolicies"].select{|e| e["PolicyName"] == "fog-lb-no-expiry"} }

      returns([
               "fog-policy"
              ]) { lb["Policies"]["OtherPolicies"] }
    end

    tests("#delete_load_balancer_policy").formats(AWS::ELB::Formats::BASIC) do
      policy = 'fog-lb-no-expiry'
      Fog::AWS[:elb].delete_load_balancer_policy(@load_balancer_id, policy).body
    end

    tests("#set_load_balancer_policies_of_listener adds policy").formats(AWS::ELB::Formats::BASIC) do
      port, policies = 80, ['fog-lb-expiry']
      Fog::AWS[:elb].set_load_balancer_policies_of_listener(@load_balancer_id, port, policies).body
    end

    tests("#set_load_balancer_policies_of_listener removes policy").formats(AWS::ELB::Formats::BASIC) do
      port = 80
      Fog::AWS[:elb].set_load_balancer_policies_of_listener(@load_balancer_id, port, []).body
    end

    proxy_policy = "EnableProxyProtocol"
    Fog::AWS[:elb].create_load_balancer_policy(@load_balancer_id, proxy_policy, 'ProxyProtocolPolicyType', { "ProxyProtocol" => true })

    tests("#set_load_balancer_policies_for_backend_server replaces policies on port").formats(AWS::ELB::Formats::BASIC) do
      Fog::AWS[:elb].set_load_balancer_policies_for_backend_server(@load_balancer_id, 80, [proxy_policy]).body
    end

    tests("#describe_load_balancers has other policies") do
      Fog::AWS[:elb].set_load_balancer_policies_for_backend_server(@load_balancer_id, 80, [proxy_policy]).body
      description = Fog::AWS[:elb].describe_load_balancers("LoadBalancerNames" => [@load_balancer_id]).body["DescribeLoadBalancersResult"]["LoadBalancerDescriptions"].first
      returns(true) { description["Policies"]["OtherPolicies"].include?(proxy_policy) }
    end

    Fog::AWS[:elb].delete_load_balancer(@load_balancer_id)
  end
end
