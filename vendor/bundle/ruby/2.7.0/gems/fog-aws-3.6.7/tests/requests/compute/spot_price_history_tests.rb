Shindo.tests('Fog::Compute[:aws] | spot price history requests', ['aws']) do

  @spot_price_history_format = {
    'spotPriceHistorySet'   => [{
      'availabilityZone'    => String,
      'instanceType'        => String,
      'spotPrice'           => Float,
      'productDescription'  => String,
      'timestamp'           => Time
    }],
    'requestId' => String,
    'nextToken' => Fog::Nullable::String
  }

  tests('success') do

    tests("#describe_spot_price_history").formats(@spot_price_history_format) do
      Fog::Compute[:aws].describe_spot_price_history.body
    end

  end

end
