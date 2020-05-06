require File.dirname(__FILE__) + '/../spec_helper'
require 'ladle'

describe OpenProject::LdapGroups::Synchronization, with_ee: %i[ldap_groups] do
  let(:plugin_settings) do
    {group_base: 'ou=groups,dc=example,dc=com', group_key: 'cn'}
  end

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
                      base_dn: 'ou=people,dc=example,dc=com',
                      onthefly_register: onthefly_register,
                      filter_string: ldap_filter,
                      attr_login: 'uid',
                      attr_firstname: 'givenName',
                      attr_lastname: 'sn',
                      attr_mail: 'mail'
  end

  let(:onthefly_register) { false }
  let(:ldap_filter) { nil }

  let(:user_aa729) { FactoryBot.create :user, login: 'aa729', auth_source: auth_source }
  let(:user_bb459) { FactoryBot.create :user, login: 'bb459', auth_source: auth_source }
  let(:user_cc414) { FactoryBot.create :user, login: 'cc414', auth_source: auth_source }

  let(:group_foo) { FactoryBot.create :group, lastname: 'foo_internal' }
  let(:group_bar) { FactoryBot.create :group, lastname: 'bar' }

  let(:synced_foo) { FactoryBot.create :ldap_synchronized_group, dn: 'cn=foo,ou=groups,dc=example,dc=com', group: group_foo, auth_source: auth_source }
  let(:synced_bar) { FactoryBot.create :ldap_synchronized_group, dn: 'cn=bar,ou=groups,dc=example,dc=com', group: group_bar, auth_source: auth_source }

  subject do
    # Need the system user for admin permission
    User.system.run_given do
      described_class.new auth_source
    end
  end

  shared_examples 'does not change membership count' do
    it 'does not change membership count' do
      subject

      expect(group_foo.users).to be_empty
      expect(group_bar.users).to be_empty

      expect(synced_foo.users).to be_empty
      expect(synced_bar.users).to be_empty
    end
  end

  describe 'adding memberships' do
    context 'when no synced group exists' do
      before do
        user_aa729
        user_bb459
        user_cc414
      end

      it_behaves_like 'does not change membership count'
    end

    context 'when one synced group exists' do
      before do
        group_foo
        synced_foo
      end

      context 'when no users exist' do
        it_behaves_like 'does not change membership count'
      end

      context 'when one mapped user exists' do
        before do
          user_aa729
        end

        it 'synchronized the membership of aa729 to foo' do
          subject
          expect(synced_foo.users.count).to eq(1)
          expect(group_foo.users).to eq([user_aa729])
        end
      end
    end

    context 'when all groups exist' do
      before do
        group_foo
        synced_foo
        group_bar
        synced_bar
      end

      context 'and all users exist' do
        before do
          user_aa729
          user_bb459
          user_cc414
        end


        describe 'synchronizes all memberships' do
          before do
            subject

            expect(synced_foo.users.count).to eq(1)
            expect(synced_bar.users.count).to eq(3)

            expect(group_foo.users).to eq([user_aa729])
            expect(group_bar.users).to eq([user_aa729, user_bb459, user_cc414])
          end

          it 'removes all memberships after removing synced group' do
            synced_foo_id = synced_foo.id
            expect(::LdapGroups::Membership.where(group_id: synced_foo_id).count).to eq(1)
            synced_foo.destroy

            expect { group_foo.reload }.not_to raise_error

            expect(::LdapGroups::Membership.where(group_id: synced_foo_id)).to be_empty
          end

          it 'removes all memberships and groups after removing auth source' do
            expect { auth_source.destroy! }
              .to change { ::LdapGroups::Membership.count }.from(4).to(0)

            expect { synced_foo.reload }.to raise_error ActiveRecord::RecordNotFound
            expect { synced_bar.reload }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'removes all memberships and groups after removing actual group' do
            synced_foo_id = synced_foo.id
            expect(::LdapGroups::Membership.where(group_id: synced_foo_id).count).to eq(1)
            group_foo.destroy

            expect { synced_foo.reload }.to raise_error ActiveRecord::RecordNotFound
            expect(group_bar.users).to eq([user_aa729, user_bb459, user_cc414])

            expect(::LdapGroups::Membership.where(group_id: synced_foo_id)).to be_empty
          end
        end
      end

      context 'and only one user of bar exists' do
        before do
          user_cc414
        end

        it 'synchronized that membership' do
          subject
          expect(synced_foo.users.count).to eq(0)
          expect(synced_bar.users.count).to eq(1)

          expect(group_foo.users).to be_empty
          expect(group_bar.users).to eq([user_cc414])
        end

        context 'with LDAP on-the-fly enabled' do
          let(:onthefly_register) { true }
          let(:user_aa729) { User.find_by login: 'aa729' }
          let(:user_bb459) { User.find_by login: 'bb459' }

          it 'creates the remaining users' do
            subject
            expect(synced_foo.users.count).to eq(1)
            expect(synced_bar.users.count).to eq(3)

            expect(group_foo.users).to contain_exactly(user_aa729)
            expect(group_bar.users).to contain_exactly(user_aa729, user_bb459, user_cc414)
          end
        end

        context 'with an LDAP filter for users starting with b and on-the-fly enabled' do
          let(:onthefly_register) { true }
          let(:ldap_filter) { '(uid=b*)' }
          let(:user_bb459) { User.find_by login: 'bb459' }

          it 'creates the remaining users' do
            subject
            expect(synced_foo.users.count).to eq(0)
            expect(synced_bar.users.count).to eq(1)

            expect(User.find_by(login: 'aa729')).to eq nil
            # Only matched users are added to the group, meaning cc414 is not added
            expect(group_bar.users).to contain_exactly(user_bb459)
          end
        end
      end
    end

    context 'foo group exists' do
      let(:group_foo) { FactoryBot.create :group, lastname: 'foo_internal', members: user_aa729 }

      before do
        group_foo
        synced_foo
      end

      it 'ignores users that are already in the group' do
        # Outputs that nothing was added to sync group
        expect(Rails.logger).to receive(:info).with("[LDAP groups] No users to remove for cn=foo,ou=groups,dc=example,dc=com")
        expect(Rails.logger).to receive(:info).with("[LDAP groups] No new users to add for cn=foo,ou=groups,dc=example,dc=com")

        subject

        # Does not add to synced group since added manually
        expect(synced_foo.users.count).to eq(0)
      end
    end
  end

  describe 'removing memberships' do
    context 'with a user in a group thats not in ldap' do
      let(:group_foo) { FactoryBot.create :group, lastname: 'foo_internal', members: [user_cc414, user_aa729] }

      before do
        synced_foo.users.create(user: user_aa729)
        synced_foo.users.create(user: user_cc414)

        subject
      end

      it 'removes the membership' do
        group_foo.reload
        synced_foo.reload

        expect(group_foo.users).to eq([user_aa729])
        expect(synced_foo.users.pluck(:user_id)).to eq([user_aa729.id])
      end
    end
  end

  context 'with invalid connection' do
    let(:auth_source) { FactoryBot.create :ldap_auth_source }

    before do
      synced_foo
    end

    it 'does not raise, but print to stderr' do
      expect(Rails.logger).to receive(:error).with(/Failed to perform LDAP group synchronization/)
      subject
    end
  end

  context 'with invalid base' do
    let(:synced_foo) { FactoryBot.create :ldap_synchronized_group, dn: 'cn=foo,ou=invalid,dc=example,dc=com', group: group_foo, auth_source: auth_source }
    let(:synced_bar) { FactoryBot.create :ldap_synchronized_group, dn: 'cn=bar,ou=invalid,dc=example,dc=com', group: group_bar, auth_source: auth_source }

    context 'when one synced group exists' do
      before do
        group_foo
        synced_foo
        user_aa729
      end

      it 'does not find the group and syncs no user' do
        subject
        expect(synced_foo.users).to be_empty
        expect(group_foo.users).to eq([])
      end
    end
  end
end
