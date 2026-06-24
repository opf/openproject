# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizedTree do
  let(:ldap_auth_source) { create(:ldap_auth_source, base_dn: "dc=example,dc=com") }

  subject { build(:ldap_synchronized_tree, ldap_auth_source:, base_dn:) }

  context "with a base DN inside the auth source base" do
    let(:base_dn) { "ou=IT,dc=example,dc=com" }

    it { is_expected.to be_valid }
  end

  context "with a base DN equal to the auth source base" do
    let(:base_dn) { "dc=example,dc=com" }

    it { is_expected.to be_valid }
  end

  context "with a base DN outside the auth source base" do
    let(:base_dn) { "ou=IT,dc=other,dc=com" }

    it "is invalid" do
      expect(subject).not_to be_valid
      expect(subject.errors[:base_dn]).to be_present
    end
  end

  context "with an invalid structure filter" do
    let(:base_dn) { "dc=example,dc=com" }

    it "is invalid" do
      subject.structure_filter_string = "(objectClass="
      expect(subject).not_to be_valid
      expect(subject.errors[:structure_filter_string]).to be_present
    end
  end

  describe "overlap with sibling trees" do
    let(:base_dn) { "ou=IT,dc=example,dc=com" }

    before { create(:ldap_synchronized_tree, ldap_auth_source:, base_dn: "ou=IT,dc=example,dc=com") }

    it "rejects an identical base" do
      expect(subject).not_to be_valid
      expect(subject.errors[:base_dn]).to be_present
    end

    it "rejects a descendant base" do
      subject.base_dn = "ou=Development,ou=IT,dc=example,dc=com"
      expect(subject).not_to be_valid
    end

    it "allows a disjoint base" do
      subject.base_dn = "ou=HR,dc=example,dc=com"
      expect(subject).to be_valid
    end
  end
end
