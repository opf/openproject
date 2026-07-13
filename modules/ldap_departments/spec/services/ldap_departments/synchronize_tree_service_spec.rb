# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizeTreeService do
  subject(:service_call) { described_class.new(tree).call }

  let(:ldap_auth_source) { create(:ldap_auth_source, base_dn: "dc=example,dc=com", attr_login: "uid") }
  let(:base_dn) { "dc=example,dc=com" }
  let(:guid_attribute) { nil }
  let(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:, base_dn:, guid_attribute:) }

  # OUs returned by the directory. The base DN entry is intentionally included to verify it is skipped.
  let(:ou_entries) do
    [
      ou_entry("dc=example,dc=com", nil),
      ou_entry("ou=IT,dc=example,dc=com", "IT"),
      ou_entry("ou=Development,ou=IT,dc=example,dc=com", "Development"),
      ou_entry("ou=Frontend,ou=Development,ou=IT,dc=example,dc=com", "Frontend"),
      ou_entry("ou=Human Resources,dc=example,dc=com", "Human Resources"),
      ou_entry("ou=Support,ou=IT,dc=example,dc=com", "Support"),
      ou_entry("ou=Support,ou=Human Resources,dc=example,dc=com", "Support")
    ]
  end

  def ou_entry(dn_value, ou_value, guid: nil)
    entry = Net::LDAP::Entry.new(dn_value)
    entry[:objectClass] = ["organizationalUnit"]
    entry[:ou] = [ou_value] if ou_value
    entry[:objectGUID] = [guid] if guid
    entry
  end

  before do
    connection = instance_double(Net::LDAP)
    allow(ldap_auth_source).to receive(:with_connection).and_yield(connection)
    allow(connection).to receive(:search) do |**opts, &block|
      base = LdapDepartments::Dn.normalize(opts[:base])
      ou_entries
        .select { |entry| LdapDepartments::Dn.normalize(entry.dn).end_with?(base) }
        .each(&block)
    end
    allow(tree).to receive(:ldap_auth_source).and_return(ldap_auth_source)
  end

  def department(name)
    Group.organizational_units.find_by(lastname: name)
  end

  it "mirrors the full OU hierarchy into departments" do
    expect(service_call).to be_success

    it_department = department("IT")
    development = department("Development")
    frontend = department("Frontend")

    expect(it_department).to be_present
    expect(it_department.parent_id).to be_nil
    expect(development.parent_id).to eq(it_department.id)
    expect(frontend.parent_id).to eq(development.id)
    expect(department("Human Resources").parent_id).to be_nil
  end

  it "allows the same OU name on different branches" do
    service_call

    supports = Group.organizational_units.where(lastname: "Support")
    expect(supports.count).to eq(2)
    expect(supports.map(&:parent_id)).to contain_exactly(department("IT").id, department("Human Resources").id)
  end

  it "does not create a department for the base DN itself" do
    service_call

    expect(Group.organizational_units.where(lastname: "example")).to be_empty
    expect(LdapDepartments::SynchronizedDepartment.where(dn: "dc=example,dc=com")).to be_empty
  end

  context "with a base DN deeper in the tree" do
    let(:base_dn) { "ou=IT,dc=example,dc=com" }

    it "only synchronizes OUs below that base" do
      service_call

      expect(department("Development").parent_id).to be_nil
      expect(department("Frontend").parent_id).to eq(department("Development").id)
      expect(department("Human Resources")).to be_nil
    end
  end

  describe "removal of an OU" do
    let!(:existing) do
      service_call
      department("Frontend")
    end

    it "keeps the department but drops the mapping when the OU disappears" do
      ou_entries.reject! { |entry| entry.dn.start_with?("ou=Frontend") }

      described_class.new(tree).call

      expect(department("Frontend")).to be_present
      expect(LdapDepartments::SynchronizedDepartment.where(dn: "ou=Frontend,ou=Development,ou=IT,dc=example,dc=com"))
        .to be_empty
    end
  end

  describe "stable identity via GUID" do
    let(:guid_attribute) { "objectGUID" }
    let(:ou_entries) do
      [ou_entry("ou=IT,dc=example,dc=com", "IT", guid: "guid-it")]
    end

    it "updates the same department when the OU is renamed" do
      service_call
      original = department("IT")

      ou_entries.replace([ou_entry("ou=Information,dc=example,dc=com", "Information", guid: "guid-it")])
      described_class.new(tree).call

      expect(department("Information")&.id).to eq(original.id)
      expect(LdapDepartments::SynchronizedDepartment.find_by(ldap_entry_uuid: "guid-it").dn)
        .to eq("ou=Information,dc=example,dc=com")
    end
  end
end
