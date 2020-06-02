require File.dirname(__FILE__) + '/../spec_helper'
require 'ladle'

describe OpenProject::LdapGroups::SynchronizeFilter, with_ee: %i[ldap_groups] do
  before(:all) do
    ldif = Rails.root.join('spec/fixtures/ldap/users.ldif')
    @ldap_server = Ladle::Server.new(quiet: false, port: '12389', domain: 'dc=example,dc=com', ldif: ldif).start
  end

  after(:all) do
    @ldap_server.stop
  end

  # Ldap has:
  # three users aa729, bb459, cc414
  # two groups foo (aa729), bar(aa729, bb459, cc414)
  let(:auth_source) do
    FactoryBot.create :ldap_auth_source,
                      port: '12389',
                      account: 'uid=admin,ou=system',
                      account_password: 'secret',
                      base_dn: 'dc=example,dc=com',
                      attr_login: 'uid'
  end

  let(:user_aa729) { FactoryBot.create :user, login: 'aa729', auth_source: auth_source }
  let(:user_bb459) { FactoryBot.create :user, login: 'bb459', auth_source: auth_source }
  let(:user_cc414) { FactoryBot.create :user, login: 'cc414', auth_source: auth_source }

  let(:group_foo) { FactoryBot.create :group, lastname: 'foo' }
  let(:group_bar) { FactoryBot.create :group, lastname: 'bar' }

  let(:synced_foo) { FactoryBot.create :ldap_synchronized_group, dn: 'cn=foo,ou=groups,dc=example,dc=com', group: group_foo, auth_source: auth_source }
  let(:synced_bar) { FactoryBot.create :ldap_synchronized_group, dn: 'cn=bar,ou=groups,dc=example,dc=com', group: group_bar, auth_source: auth_source }

  let(:filter_foo_bar) { FactoryBot.create :ldap_synchronized_filter, auth_source: auth_source }

  subject { described_class.new filter_foo_bar }

  shared_examples 'has foo and bar synced groups' do
    it 'creates the two groups' do
      expect { subject }.not_to raise_error

      filter_foo_bar.reload

      # Expect two synchronized groups added
      expect(filter_foo_bar.groups.count).to eq 2
      expect(filter_foo_bar.groups.map(&:dn)).to match_array ['cn=foo,ou=groups,dc=example,dc=com', 'cn=bar,ou=groups,dc=example,dc=com']

      # Expect two actual groups added
      op_foo_group = Group.find_by(lastname: 'foo')
      op_bar_group = Group.find_by(lastname: 'bar')
      expect(op_foo_group).to be_present
      expect(op_bar_group).to be_present

      sync_foo_group = LdapGroups::SynchronizedGroup.find_by(dn: 'cn=foo,ou=groups,dc=example,dc=com')
      sync_bar_group = LdapGroups::SynchronizedGroup.find_by(dn: 'cn=bar,ou=groups,dc=example,dc=com')
      expect(sync_foo_group.group).to eq op_foo_group
      expect(sync_bar_group.group).to eq op_bar_group
    end
  end

  describe 'when filter is new and nothing exists' do
    it_behaves_like 'has foo and bar synced groups'
  end

  describe 'when one group already exists' do
    before do
      synced_foo
    end

    it_behaves_like 'has foo and bar synced groups'

    it 'the group is taken over by the filter' do
      expect { subject }.not_to raise_error

      synced_foo.reload
      expect(synced_foo.filter).to eq filter_foo_bar
    end
  end

  describe 'when it has a group that no longer exists in ldap' do
    let!(:group_doesnotexist) { FactoryBot.create :group, lastname: 'doesnotexist' }
    let!(:synced_doesnotexist) do
      FactoryBot.create :ldap_synchronized_group,
                        dn: 'cn=doesnotexist,ou=groups,dc=example,dc=com',
                        group: group_doesnotexist,
                        filter: filter_foo_bar,
                        auth_source: auth_source
    end

    it 'removes that group' do
      expect { subject }.not_to raise_error
      expect { synced_doesnotexist.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
