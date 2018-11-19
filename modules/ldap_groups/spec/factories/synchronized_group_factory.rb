FactoryBot.define do
  factory :ldap_synchronized_group, class: ::LdapGroups::SynchronizedGroup do
    entry 'uid'
    group factory: :group
    auth_source factory: :ldap_auth_source
  end
end

