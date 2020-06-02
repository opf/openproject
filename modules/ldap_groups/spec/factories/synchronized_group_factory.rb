FactoryBot.define do
  factory :ldap_synchronized_group, class: ::LdapGroups::SynchronizedGroup do
    dn { 'cn=foo,ou=groups,dc=example,dc=com' }
    group factory: :group
    auth_source factory: :ldap_auth_source
  end
end

