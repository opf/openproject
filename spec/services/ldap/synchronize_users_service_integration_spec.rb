require "spec_helper"

RSpec.describe Ldap::SynchronizeUsersService do
  include_context "with temporary LDAP"

  subject do
    described_class.new(ldap_auth_source).call
  end

  context "when updating an admin" do
    let!(:user_aa729) { create(:user, login: "aa729", firstname: "Foobar", ldap_auth_source:, admin: true) }

    it "does not update the admin attribute if not defined (Regression #42396)" do
      expect(user_aa729).to be_admin

      subject

      expect(user_aa729.reload).to be_admin
    end
  end

  context "when updating users" do
    let!(:user_aa729) { create(:user, login: "aa729", firstname: "Foobar", ldap_auth_source:) }
    let!(:user_bb459) { create(:user, login: "bb459", firstname: "Bla", ldap_auth_source:) }

    context "when user sync status is enabled",
            with_config: { ldap_users_sync_status: true } do
      it "updates the attributes of those users" do
        subject

        user_aa729.reload
        user_bb459.reload

        expect(user_aa729.firstname).to eq "Alexandra"
        expect(user_aa729.lastname).to eq "Adams"
        expect(user_aa729.mail).to eq "alexandra@example.org"

        expect(user_bb459.firstname).to eq "Belle"
        expect(user_bb459.lastname).to eq "Baldwin"
        expect(user_bb459.mail).to eq "belle@example.org"
      end

      it "updates one user if the other fails" do
        allow(Users::UpdateService)
          .to receive(:new)
                .and_call_original

        allow(Users::UpdateService)
          .to receive(:new)
                .with(model: user_aa729, user: User.system)
                .and_raise("Some bad error happening here")

        subject

        user_aa729.reload
        user_bb459.reload

        expect(user_aa729.firstname).to eq "Foobar"
        expect(user_aa729.lastname).to eq "Bobbit"

        expect(user_bb459.firstname).to eq "Belle"
        expect(user_bb459.lastname).to eq "Baldwin"
        expect(user_bb459.mail).to eq "belle@example.org"
      end

      it "reactivates the account if it is locked" do
        user_aa729.lock!

        expect(user_aa729.reload).to be_locked

        subject

        expect(user_aa729.reload).not_to be_locked
        expect(user_aa729).to be_active
      end

      context "with a user that is in another LDAP" do
        let(:auth_source2) { create(:ldap_auth_source, name: "Another LDAP") }
        let(:user_foo) { create(:user, login: "login", ldap_auth_source: auth_source2) }

        it "does not touch that user" do
          expect(user_foo).to be_active

          subject

          expect(user_foo.reload).to be_active
        end
      end
    end

    context "when user sync status is disabled",
            with_config: { ldap_users_sync_status: false } do
      it "does not reactivate the account if it is locked" do
        user_aa729.lock!

        expect(user_aa729.reload).to be_locked

        subject

        expect(user_aa729.reload).to be_locked
        expect(user_aa729).not_to be_active
      end
    end

    context "when requesting only a subset of users" do
      let!(:user_cc414) { create(:user, login: "cc414", ldap_auth_source:) }

      subject do
        described_class.new(ldap_auth_source, %w[Aa729 cc414]).call
      end

      it "syncs all case-insensitive users" do
        subject

        user_aa729.reload
        user_bb459.reload
        user_cc414.reload

        expect(user_aa729.firstname).to eq "Alexandra"
        expect(user_aa729.lastname).to eq "Adams"
        expect(user_aa729.mail).to eq "alexandra@example.org"

        expect(user_cc414.firstname).to eq "Claire"
        expect(user_cc414.lastname).to eq "Carpenter"
        expect(user_cc414.mail).to eq "claire@example.org"

        expect(user_bb459.firstname).to eq "Bla"
        expect(user_bb459.lastname).to eq "Bobbit"
      end
    end
  end

  context "with a user that is no longer in LDAP" do
    let(:user_foo) { create(:user, login: "login", ldap_auth_source:) }

    context "when user sync status is enabled",
            with_config: { ldap_users_sync_status: true } do
      it "locks that user" do
        expect(user_foo).to be_active

        subject

        expect(user_foo.reload).to be_locked
      end
    end

    context "when user sync status is disabled",
            with_config: { ldap_users_sync_status: false } do
      it "does not lock that user" do
        expect(user_foo).to be_active

        subject

        expect(user_foo.reload).to be_active
      end
    end
  end
end
