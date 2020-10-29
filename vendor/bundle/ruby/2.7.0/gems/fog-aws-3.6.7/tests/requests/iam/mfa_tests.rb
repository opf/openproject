Shindo.tests('AWS::IAM | mfa requests', ['aws']) do

  tests('success') do
    @mfa_devices_format = {
      'MFADevices' => [{
        'EnableDate'    => Time,
        'SerialNumber'  => String,
        'UserName'      => String
      }],
      'IsTruncated' => Fog::Boolean,
      'RequestId'   => String
    }

    tests('#list_mfa_devices').formats(@mfa_devices_format) do
      Fog::AWS[:iam].list_mfa_devices.body
    end
  end

  tests('failure') do
    test('failing conditions')
  end

end
