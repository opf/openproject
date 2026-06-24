# frozen_string_literal: true

FactoryBot.define do
  factory :ldap_synchronized_tree, class: "::LdapDepartments::SynchronizedTree" do
    sequence(:name) { |n| "Tree #{n}" }
    base_dn { "dc=example,dc=com" }
    ldap_auth_source
  end
end
