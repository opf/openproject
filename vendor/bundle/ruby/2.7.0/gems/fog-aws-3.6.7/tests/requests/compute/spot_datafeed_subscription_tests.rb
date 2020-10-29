Shindo.tests('Fog::Compute[:aws] | spot datafeed subscription requests', ['aws']) do
  @spot_datafeed_subscription_format = {
    'spotDatafeedSubscription' => {
      'bucket'  => String,
      'ownerId' => String,
      'prefix'  => String,
      'state'   => String
    },
    'requestId' => String
  }

  @directory = Fog::Storage[:aws].directories.create(:key => 'fogspotdatafeedsubscriptiontests')

  tests('success') do
    pending if Fog.mocking?

    tests("#create_spot_datafeed_subscription('fogspotdatafeedsubscriptiontests', 'fogspotdatafeedsubscription/')").formats(@spot_datafeed_subscription_format) do
      Fog::Compute[:aws].create_spot_datafeed_subscription('fogspotdatafeedsubscriptiontests', 'fogspotdatafeedsubscription/').body
    end

    tests("duplicate #create_spot_datafeed_subscription('fogspotdatafeedsubscriptiontests', 'fogspotdatafeedsubscription/')").succeeds do
      Fog::Compute[:aws].create_spot_datafeed_subscription('fogspotdatafeedsubscriptiontests', 'fogspotdatafeedsubscription/')
    end

    tests("#describe_spot_datafeed_subscription").formats(@spot_datafeed_subscription_format) do
      Fog::Compute[:aws].describe_spot_datafeed_subscription.body
    end

    tests("#delete_spot_datafeed_subscription").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_spot_datafeed_subscription.body
    end

    tests("duplicate #delete_spot_datafeed_subscription").succeeds do
      Fog::Compute[:aws].delete_spot_datafeed_subscription
    end
  end

  tests('failure') do
    pending if Fog.mocking?

    tests("#describe_spot_datafeed_subscription").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].describe_spot_datafeed_subscription
    end
  end

  @directory.destroy
end
