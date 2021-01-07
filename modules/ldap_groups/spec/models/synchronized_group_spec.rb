require 'spec_helper'

describe LdapGroups::SynchronizedGroup, type: :model do
  describe 'validations' do
    subject { FactoryBot.build :ldap_synchronized_group }

    context 'correct attributes' do
      it 'saves the record' do
        expect(subject.save).to eq true
      end
    end

    context 'missing attributes' do
      subject { described_class.new }
      it 'validates missing attributes' do
        expect(subject.save).to eq false
        expect(subject.errors[:dn]).to include "can't be blank."
        expect(subject.errors[:auth_source]).to include "can't be blank."
        expect(subject.errors[:group]).to include "can't be blank."
      end
    end
  end

  describe 'manipulating members' do
    let(:users) { [user_1, user_2] }
    let(:user_1) { FactoryBot.create :user }
    let(:user_2) { FactoryBot.create :user }

    describe '.add_members!' do
      let(:synchronized_group) { FactoryBot.create :ldap_synchronized_group, group: group }
      let(:group) { FactoryBot.create :group }

      shared_examples 'it adds users to the synchronized group and the internal one' do
        let(:members) { raise "define me!" }

        before do
          expect(synchronized_group.users).to be_empty
          expect(group.users).to be_empty

          User.system.run_given do
            synchronized_group.add_members! members
          end
        end

        it 'adds the user(s) to the internal group' do
          expect(group.reload.users).to match_array users
        end

        it 'adds the user(s) to the synchronized group' do
          expect(synchronized_group.reload.users.map(&:user)).to match_array users
        end
      end

      context 'called with user records' do
        it_behaves_like 'it adds users to the synchronized group and the internal one' do
          let(:members) { users }
        end
      end

      context 'called just with user IDs' do
        it_behaves_like 'it adds users to the synchronized group and the internal one' do
          let(:members) { users.pluck(:id) }
        end
      end
    end

    describe '.remove_members!' do
      let(:synchronized_group) do
        FactoryBot.create(:ldap_synchronized_group, group: group).tap do |sg|
          group.users.each do |user|
            sg.users.create user: user
          end
        end
      end
      let(:group) { FactoryBot.create :group, members: users }

      shared_examples 'it removes the users from the synchronized group and the internal one' do
        let(:members) { raise "define me!" }

        before do
          synchronized_group.remove_members! members
        end

        it 'removes the user(s) from the internal group' do
          expect(group.reload.users).to be_empty
        end

        it 'removes the users(s) from the synchronized group' do
          expect(synchronized_group.users).to be_empty
        end

        it 'does not, however, delete the actual users!' do
          expect(User.find(users.map(&:id))).to match_array users
        end
      end

      context 'called with user records' do
        it_behaves_like 'it removes the users from the synchronized group and the internal one' do
          let(:members) { group.users }
        end
      end

      context 'called just with user IDs' do
        it_behaves_like 'it removes the users from the synchronized group and the internal one' do
          let(:members) { group.users.pluck(:id) }
        end
      end
    end
  end
end
