# frozen_string_literal: true

FactoryBot.define do
  factory :ldap_synchronized_department, class: "::LdapDepartments::SynchronizedDepartment" do
    synchronized_tree factory: :ldap_synchronized_tree
    group factory: :department
    ldap_auth_source { synchronized_tree.ldap_auth_source }
    sequence(:dn) { |n| "ou=Department #{n},dc=example,dc=com" }
  end
end
