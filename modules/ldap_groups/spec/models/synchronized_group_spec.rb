require "spec_helper"

RSpec.describe LdapGroups::SynchronizedGroup do
  describe "validations" do
    subject { build(:ldap_synchronized_group) }

    context "correct attributes" do
      it "saves the record" do
        expect(subject.save).to be true
      end
    end

    context "missing attributes" do
      subject { described_class.new }

      it "validates missing attributes" do
        expect(subject.save).to be false
        expect(subject.errors[:dn]).to include "can't be blank."
        expect(subject.errors[:ldap_auth_source]).to include "can't be blank."
        expect(subject.errors[:group]).to include "can't be blank."
      end
    end
  end

  describe "manipulating members" do
    let(:users) { [user1, user2] }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    describe ".add_members!" do
      let(:synchronized_group) { create(:ldap_synchronized_group, group:) }
      let(:group) { create(:group) }

      shared_examples "it adds users to the synchronized group and the internal one" do
        let(:members) { raise "define me!" }

        before do
          expect(synchronized_group.users).to be_empty
          expect(group.users).to be_empty

          User.system.run_given do
            synchronized_group.add_members! members
          end
        end

        it "adds the user(s) to the internal group" do
          expect(group.reload.users).to match_array users
        end

        it "adds the user(s) to the synchronized group" do
          expect(synchronized_group.reload.users.map(&:user)).to match_array users
        end
      end

      context "called with user records" do
        it_behaves_like "it adds users to the synchronized group and the internal one" do
          let(:members) { users }
        end
      end

      context "called just with user IDs" do
        it_behaves_like "it adds users to the synchronized group and the internal one" do
          let(:members) { users.pluck(:id) }
        end
      end
    end

    describe ".remove_members!" do
      let(:synchronized_group) do
        create(:ldap_synchronized_group, group:).tap do |sg|
          group.users.each do |user|
            sg.users.create user:
          end
        end
      end
      let(:group) { create(:group, members: users) }

      shared_examples "it removes the users from the synchronized group and the internal one" do
        let(:members) { raise "define me!" }

        before do
          synchronized_group.remove_members! members
        end

        it "removes the user(s) from the internal group" do
          expect(group.reload.users).to be_empty
        end

        it "removes the users(s) from the synchronized group" do
          expect(synchronized_group.users).to be_empty
        end

        it "does not, however, delete the actual users!" do
          expect(User.find(users.map(&:id))).to match_array users
        end
      end

      context "called with user records" do
        it_behaves_like "it removes the users from the synchronized group and the internal one" do
          let(:members) { group.users }
        end
      end

      context "called just with user IDs" do
        it_behaves_like "it removes the users from the synchronized group and the internal one" do
          let(:members) { group.users.pluck(:id) }
        end
      end

      context "when the service call fails for any reason" do
        let(:service) { instance_double(Groups::UpdateService) }
        let(:failure_result) { ServiceResult.failure(message: "oh noes") }

        it "does not commit the changes" do
          allow(Groups::UpdateService).to receive(:new).and_return(service)
          allow(service).to receive(:call).and_return(failure_result)

          user_ids = synchronized_group.users.pluck(:id)

          expect(user_ids.count).to eq 2

          expect { synchronized_group.remove_members! user_ids }.not_to raise_error

          synchronized_group.reload

          expect(synchronized_group.users.pluck(:id)).to match_array(user_ids)
        end
      end
    end
  end
end
