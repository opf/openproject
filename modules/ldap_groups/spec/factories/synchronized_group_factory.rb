FactoryBot.define do
  factory :ldap_synchronized_group, class: "::LdapGroups::SynchronizedGroup" do
    dn { "cn=foo,ou=groups,dc=example,dc=com" }
    group factory: :group
    ldap_auth_source
    sync_users { true }
  end
end
