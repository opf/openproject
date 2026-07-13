# frozen_string_literal: true

require_relative "../spec_helper"
require "ladle"

# Full end-to-end synchronization against a real (Ladle/ApacheDS) LDAP server using the nested
# organizational unit tree below ou=org in spec/fixtures/ldap/users.ldif:
#
#   ou=org
#     ou=IT
#       ou=Development
#         ou=Frontend  (uid=jdoe)
#         ou=Backend   (uid=bsmith)
#       ou=Support
#     ou=Human Resources
#       ou=Recruiting  (uid=hwest)
#       ou=Support     (duplicate name on a different branch)
RSpec.describe "LDAP department synchronization (integration)", :aggregate_failures, # rubocop:disable RSpec/DescribeClass
               with_ee: %i[ldap_groups] do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    ldif = Rails.root.join("spec/fixtures/ldap/users.ldif")
    @ldap_server = Ladle::Server.new(quiet: true,
                                     port: ParallelHelper.port_for_ldap.to_s,
                                     domain: "dc=example,dc=com",
                                     ldif:).start
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    @ldap_server&.stop # rubocop:disable RSpec/InstanceVariable
  end

  let(:ldap_auth_source) do
    create(:ldap_auth_source,
           port: ParallelHelper.port_for_ldap.to_s,
           account: "uid=admin,ou=system",
           account_password: "secret",
           base_dn: "dc=example,dc=com",
           attr_login: "uid",
           attr_firstname: "givenName",
           attr_lastname: "sn",
           attr_mail: "mail",
           attr_admin: "isAdmin")
  end

  let(:base_dn) { "ou=org,dc=example,dc=com" }
  let(:sync_users) { true }
  let(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:, base_dn:, sync_users:) }

  def department(name)
    Group.organizational_units.find_by(lastname: name)
  end

  def run_sync
    LdapDepartments::SynchronizeTreeService.new(tree).call
    LdapDepartments::SynchronizeMembersService.new(tree).call
  end

  describe "the organizational unit structure" do
    before { run_sync }

    it "mirrors the nested hierarchy below the base DN" do
      expect(department("IT").parent_id).to be_nil
      expect(department("Human Resources").parent_id).to be_nil
      expect(department("Development").parent_id).to eq(department("IT").id)
      expect(department("Recruiting").parent_id).to eq(department("Human Resources").id)
      expect(department("Frontend").parent_id).to eq(department("Development").id)
      expect(department("Backend").parent_id).to eq(department("Development").id)
    end

    it "keeps the base DN out of the department tree" do
      expect(Group.organizational_units.where(lastname: "org")).to be_empty
    end

    it "creates both departments that share the name Support on different branches" do
      supports = Group.organizational_units.where(lastname: "Support")

      expect(supports.count).to eq(2)
      expect(supports.map(&:parent_id))
        .to contain_exactly(department("IT").id, department("Human Resources").id)
    end
  end

  describe "user assignment" do
    before { run_sync }

    it "creates users and assigns them to their containing OU's department" do
      jdoe = User.find_by(login: "jdoe")
      bsmith = User.find_by(login: "bsmith")
      hwest = User.find_by(login: "hwest")

      expect(jdoe).to be_present
      expect(department("Frontend").users).to contain_exactly(jdoe)
      expect(department("Backend").users).to contain_exactly(bsmith)
      expect(department("Recruiting").users).to contain_exactly(hwest)
      expect(department("Development").users).to be_empty
    end
  end

  describe "running the synchronization twice" do
    it "is idempotent" do
      run_sync
      expect { run_sync }.not_to(change { Group.organizational_units.count })
      expect(LdapDepartments::Membership.count).to eq(3)
    end
  end

  context "with a deeper base DN" do
    let(:base_dn) { "ou=IT,ou=org,dc=example,dc=com" }

    before { run_sync }

    it "only synchronizes OUs below that base and ignores other branches" do
      expect(department("Development").parent_id).to be_nil
      expect(department("Frontend").parent_id).to eq(department("Development").id)
      expect(department("Human Resources")).to be_nil
      expect(department("Recruiting")).to be_nil
    end
  end

  context "with sync_users disabled" do
    let(:sync_users) { false }

    before { run_sync }

    it "builds the structure but creates no users" do
      expect(department("Frontend")).to be_present
      expect(User.where(login: %w[jdoe bsmith hwest])).to be_empty
      expect(LdapDepartments::Membership.count).to eq(0)
    end
  end
end
