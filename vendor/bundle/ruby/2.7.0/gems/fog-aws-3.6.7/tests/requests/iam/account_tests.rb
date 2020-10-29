Shindo.tests('AWS::IAM | account requests', ['aws']) do
  tests('success') do
    @get_account_summary_format = {
      'Summary' => {
        'AccessKeysPerUserQuota' => Integer,
        'AccountMFAEnabled' => Integer,
        'AssumeRolePolicySizeQuota' => Fog::Nullable::Integer,
        'GroupPolicySizeQuota' => Integer,
        'Groups' => Integer,
        'GroupsPerUserQuota' => Integer,
        'GroupsQuota' => Integer,
        'InstanceProfiles' => Fog::Nullable::Integer,
        'InstanceProfilesQuota' => Fog::Nullable::Integer,
        'MFADevices' => Integer,
        'MFADevicesInUse' => Integer,
        'Providers' => Fog::Nullable::Integer,
        'RolePolicySizeQuota' => Fog::Nullable::Integer,
        'Roles' => Fog::Nullable::Integer,
        'RolesQuota' => Fog::Nullable::Integer,
        'ServerCertificates' => Integer,
        'ServerCertificatesQuota' => Integer,
        'SigningCertificatesPerUserQuota' => Integer,
        'UserPolicySizeQuota' => Integer,
        'Users' => Integer,
        'UsersQuota' => Integer,
      },
      'RequestId' => String,
    }

    tests('#get_account_summary').formats(@get_account_summary_format) do
      Fog::AWS[:iam].get_account_summary.body
    end
  end
end
