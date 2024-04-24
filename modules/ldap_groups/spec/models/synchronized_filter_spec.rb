require "spec_helper"

RSpec.describe LdapGroups::SynchronizedFilter do
  describe "#used_base_dn" do
    let(:ldap_auth_source) { build(:ldap_auth_source, base_dn: "dc=example,dc=com") }
    let(:filter) { build(:ldap_synchronized_filter, ldap_auth_source:) }

    it "validates the end of the base dn matches the ldap_auth_source" do
      filter.base_dn = nil
      expect(filter.base_dn).to be_nil
      expect(filter.used_base_dn).to eq(ldap_auth_source.base_dn)
    end
  end

  describe "#base_dn" do
    let(:ldap_auth_source) { build(:ldap_auth_source, base_dn: "dc=example,dc=com") }
    let(:filter) { build(:ldap_synchronized_filter, ldap_auth_source:) }

    it "validates the end of the base dn matches the ldap_auth_source" do
      filter.base_dn = nil
      expect(filter).to be_valid

      filter.base_dn = "dc=something,dc=else"
      expect(filter).not_to be_valid
      expect(filter.errors.details[:base_dn]).to contain_exactly(error: :must_contain_base_dn)
    end
  end
end
