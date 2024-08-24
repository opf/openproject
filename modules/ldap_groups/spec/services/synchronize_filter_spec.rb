require File.dirname(__FILE__) + "/../spec_helper"
require "ladle"

RSpec.describe LdapGroups::SynchronizeFilterService, with_ee: %i[ldap_groups] do
  before(:all) do
    ldif = Rails.root.join("spec/fixtures/ldap/users.ldif")
    @ldap_server = Ladle::Server.new(quiet: false, port: ParallelHelper.port_for_ldap.to_s, domain: "dc=example,dc=com",
                                     ldif:).start
  end

  after(:all) do
    @ldap_server.stop
  end

  # Ldap has:
  # three users aa729, bb459, cc414
  # two groups foo (aa729), bar(aa729, bb459, cc414)
  let(:ldap_auth_source) do
    create(:ldap_auth_source,
           port: ParallelHelper.port_for_ldap.to_s,
           account: "uid=admin,ou=system",
           account_password: "secret",
           base_dn: "dc=example,dc=com",
           attr_login: "uid")
  end

  let(:group_foo) { create(:group, lastname: "foo") }
  let(:group_bar) { create(:group, lastname: "bar") }

  let(:synced_foo) do
    create(
      :ldap_synchronized_group,
      dn: "cn=foo,ou=groups,dc=example,dc=com",
      group: group_foo,
      ldap_auth_source:
    )
  end
  let(:synced_bar) do
    create(
      :ldap_synchronized_group,
      dn: "cn=bar,ou=groups,dc=example,dc=com",
      group: group_bar,
      ldap_auth_source:
    )
  end

  let(:filter_foo_bar) { create(:ldap_synchronized_filter, ldap_auth_source:) }

  subject { described_class.new(filter_foo_bar).call }

  shared_examples "has foo and bar synced groups" do
    it "creates the two groups" do
      expect { subject }.not_to raise_error

      filter_foo_bar.reload

      # Expect two synchronized groups added
      expect(filter_foo_bar.groups.count).to eq 2
      expect(filter_foo_bar.groups.map(&:dn)).to contain_exactly("cn=foo,ou=groups,dc=example,dc=com",
                                                                 "cn=bar,ou=groups,dc=example,dc=com")

      # Expect two actual groups added
      op_foo_group = Group.find_by(lastname: "foo")
      op_bar_group = Group.find_by(lastname: "bar")
      expect(op_foo_group).to be_present
      expect(op_bar_group).to be_present

      sync_foo_group = LdapGroups::SynchronizedGroup.find_by(dn: "cn=foo,ou=groups,dc=example,dc=com")
      sync_bar_group = LdapGroups::SynchronizedGroup.find_by(dn: "cn=bar,ou=groups,dc=example,dc=com")
      expect(sync_foo_group.group).to eq op_foo_group
      expect(sync_bar_group.group).to eq op_bar_group
    end
  end

  describe "when filter is new and nothing exists" do
    it_behaves_like "has foo and bar synced groups"
  end

  describe "when one group already exists" do
    before do
      synced_foo
    end

    it_behaves_like "has foo and bar synced groups"

    it "the group is taken over by the filter" do
      expect { subject }.not_to raise_error

      synced_foo.reload
      expect(synced_foo.filter).to eq filter_foo_bar
    end
  end

  describe "when one group already exists with different settings" do
    let(:synced_foo) do
      create(:ldap_synchronized_group,
             dn: "cn=foo,ou=groups,dc=example,dc=com",
             group: group_foo,
             sync_users: false,
             ldap_auth_source:)
    end
    let(:filter_foo_bar) do
      create(:ldap_synchronized_filter,
             sync_users: true,
             ldap_auth_source:)
    end

    before do
      synced_foo
    end

    it "the group receives the value of the filter" do
      expect(synced_foo.sync_users).to be false
      expect { subject }.not_to raise_error

      synced_foo.reload
      expect(synced_foo.sync_users).to be true
    end
  end

  describe "when it has a group that no longer exists in ldap" do
    let!(:group_doesnotexist) { create(:group, lastname: "doesnotexist") }
    let!(:synced_doesnotexist) do
      create(:ldap_synchronized_group,
             dn: "cn=doesnotexist,ou=groups,dc=example,dc=com",
             group: group_doesnotexist,
             filter: filter_foo_bar,
             ldap_auth_source:)
    end

    it "removes that group" do
      expect { subject }.not_to raise_error
      expect { synced_doesnotexist.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "when filter has sync_users selected" do
    let(:filter_foo_bar) { create(:ldap_synchronized_filter, ldap_auth_source:, sync_users: true) }

    it "creates the groups with sync_users flag set" do
      expect { subject }.not_to raise_error

      filter_foo_bar.reload

      # Expect two synchronized groups added
      expect(filter_foo_bar.groups.count).to eq 2
      sync_foo_group = LdapGroups::SynchronizedGroup.find_by(dn: "cn=foo,ou=groups,dc=example,dc=com")
      sync_bar_group = LdapGroups::SynchronizedGroup.find_by(dn: "cn=bar,ou=groups,dc=example,dc=com")
      expect(sync_foo_group.sync_users).to be_truthy
      expect(sync_bar_group.sync_users).to be_truthy
    end
  end

  describe "when filter has its own base dn" do
    let(:filter_foo_bar) do
      create(:ldap_synchronized_filter,
             ldap_auth_source:,
             base_dn: "ou=users,dc=example,dc=com")
    end

    it "uses that base for searching and doesnt find any groups" do
      expect { subject }.not_to raise_error

      filter_foo_bar.reload

      expect(filter_foo_bar.groups.count).to eq 0
    end
  end
end
