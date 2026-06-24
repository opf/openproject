# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizeMembersService do
  subject(:service_call) { described_class.new(tree).call }

  let(:ldap_auth_source) do
    create(:ldap_auth_source,
           base_dn: "dc=example,dc=com",
           attr_login: "uid",
           attr_firstname: "givenName",
           attr_lastname: "sn",
           attr_mail: "mail")
  end
  let(:sync_users) { false }
  let(:tree) { create(:ldap_synchronized_tree, ldap_auth_source:, base_dn: "dc=example,dc=com", sync_users:) }

  let(:frontend) { create(:department, lastname: "Frontend") }
  let(:backend) { create(:department, lastname: "Backend") }
  let!(:frontend_sync) do
    create(:ldap_synchronized_department,
           synchronized_tree: tree, group: frontend,
           dn: "ou=Frontend,ou=IT,dc=example,dc=com")
  end
  let!(:backend_sync) do
    create(:ldap_synchronized_department,
           synchronized_tree: tree, group: backend,
           dn: "ou=Backend,ou=IT,dc=example,dc=com")
  end

  let(:user_entries) { [] }

  def user_entry(dn_value, uid)
    entry = Net::LDAP::Entry.new(dn_value)
    entry[:objectClass] = ["person"]
    entry[:uid] = [uid]
    entry[:givenName] = ["Given"]
    entry[:sn] = ["Surname"]
    entry[:mail] = ["#{uid}@example.com"]
    entry
  end

  before do
    connection = instance_double(Net::LDAP)
    allow(ldap_auth_source).to receive(:with_connection).and_yield(connection)
    allow(connection).to receive(:search) { |**_opts, &block| user_entries.each(&block) }
    allow(tree).to receive(:ldap_auth_source).and_return(ldap_auth_source)
  end

  context "with an existing user inside an OU" do
    let!(:user) { create(:user, login: "jdoe", ldap_auth_source:) }

    before { user_entries << user_entry("cn=John,ou=Frontend,ou=IT,dc=example,dc=com", "jdoe") }

    it "assigns the user to the matching department only" do
      expect(service_call).to be_success

      expect(frontend.reload.users).to include(user)
      expect(backend.reload.users).not_to include(user)
      expect(LdapDepartments::Membership.where(synchronized_department: frontend_sync, user:)).to exist
    end
  end

  context "when the user moves to another OU" do
    let!(:user) { create(:user, login: "jdoe", ldap_auth_source:) }

    before do
      user_entries << user_entry("cn=John,ou=Backend,ou=IT,dc=example,dc=com", "jdoe")
      described_class.new(tree).call
      user_entries.replace([user_entry("cn=John,ou=Frontend,ou=IT,dc=example,dc=com", "jdoe")])
    end

    it "moves the user out of the previous department" do
      expect(service_call).to be_success

      expect(frontend.reload.users).to include(user)
      expect(backend.reload.users).not_to include(user)
      expect(LdapDepartments::Membership.where(user:).count).to eq(1)
    end
  end

  context "when a user leaves the directory" do
    let!(:user) { create(:user, login: "jdoe", ldap_auth_source:) }

    before do
      user_entries << user_entry("cn=John,ou=Frontend,ou=IT,dc=example,dc=com", "jdoe")
      described_class.new(tree).call
      user_entries.clear
    end

    it "removes the synchronized membership" do
      expect(service_call).to be_success

      expect(frontend.reload.users).not_to include(user)
      expect(LdapDepartments::Membership.where(user:)).not_to exist
    end
  end

  context "with sync_users enabled and a missing account" do
    let(:sync_users) { true }

    before { user_entries << user_entry("cn=New,ou=Frontend,ou=IT,dc=example,dc=com", "newbie") }

    it "creates the user and assigns them" do
      expect { service_call }.to change { User.where(login: "newbie").count }.from(0).to(1)

      expect(frontend.reload.user_ids).to include(User.find_by(login: "newbie").id)
    end
  end

  context "with a user directly under the base DN" do
    let(:sync_users) { false }
    let!(:user) { create(:user, login: "jdoe", ldap_auth_source:) }

    before { user_entries << user_entry("cn=John,dc=example,dc=com", "jdoe") }

    it "leaves the user unassigned" do
      service_call

      expect(LdapDepartments::Membership.where(user:)).not_to exist
    end
  end
end
