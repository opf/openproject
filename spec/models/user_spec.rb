#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe User do
  let(:user) { build(:user) }
  let(:project) { create(:project_with_types) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:member) do
    build(:member,
          project:,
          roles: [role],
          principal: user)
  end
  let(:status) { create(:status) }
  let(:issue) do
    build(:work_package,
          type: project.types.first,
          author: user,
          project:,
          status:)
  end

  describe "with long but allowed attributes" do
    it "is valid" do
      user.firstname = "a" * 256
      user.lastname = "b" * 256
      user.mail = "fo#{'o' * 237}@mail.example.com"
      expect(user).to be_valid
      expect(user.save).to be_truthy
    end
  end

  describe "a user with and overly long firstname (> 256 chars)" do
    it "is invalid" do
      user.firstname = "a" * 257
      expect(user).not_to be_valid
      expect(user.save).to be_falsey
    end
  end

  describe "a user with and overly long lastname (> 256 chars)" do
    it "is invalid" do
      user.lastname = "a" * 257
      expect(user).not_to be_valid
      expect(user.save).to be_falsey
    end
  end

  describe "#mail" do
    before do
      user.mail = mail
    end

    context "with whitespaces" do
      let(:mail) { " foo@bar.com  " }

      it "is stripped" do
        expect(user.mail)
          .to eql "foo@bar.com"
      end
    end

    context "for local mail addresses" do
      let(:mail) { "foobar@abc.def.some-internet" }

      it "is valid" do
        expect(user).to be_valid
      end
    end

    context "for wrong mail addresses" do
      let(:mail) { "foobar+abc.def.some-internet" }

      it "is invalid" do
        expect(user).to be_invalid
      end
    end

    context "for an already taken mail addresses (different take)" do
      let(:mail) { "foo@bar.com" }
      let!(:other_user) { create(:user, mail: "Foo@Bar.com") }

      it "is invalid" do
        expect(user).to be_invalid
      end
    end
  end

  describe "#login" do
    before do
      user.login = login
    end

    context "with whitespace" do
      context "with simple spaces" do
        let(:login) { "a b  c" }

        it "is valid" do
          expect(user).to be_valid
        end

        it "may be stored in the database" do
          expect(user.save).to be_truthy
        end
      end

      context "with line breaks" do
        let(:login) { 'ab\nc' }

        it "is invalid" do
          expect(user).not_to be_valid
        end

        it "may not be stored in the database" do
          expect(user.save).to be_falsey
        end
      end

      context "with other letter char classes" do
        let(:login) { "célîneüberölig" }

        it "is valid" do
          expect(user).to be_valid
        end

        it "may be stored in the database" do
          expect(user.save).to be_truthy
        end
      end

      context "with tabs" do
        let(:login) { 'ab\tc' }

        it "is invalid" do
          expect(user).not_to be_valid
        end

        it "may not be stored in the database" do
          expect(user.save).to be_falsey
        end
      end
    end

    context "with symbols" do
      %w[+ _ . - @].each do |symbol|
        context symbol do
          let(:login) { "foo#{symbol}bar" }

          it "is valid" do
            expect(user).to be_valid
          end

          it "may be stored in the database" do
            expect(user.save).to be_truthy
          end
        end
      end

      context "with combination thereof" do
        let(:login) { "the+boss-is-über@the_house." }

        it "is valid" do
          expect(user).to be_valid
        end

        it "may be stored in the database" do
          expect(user.save).to be_truthy
        end
      end

      context "with invalid symbol" do
        let(:login) { "invalid!name" }

        it "is invalid" do
          expect(user).not_to be_valid
        end

        it "may not be stored in the database" do
          expect(user.save).to be_falsey
        end
      end
    end

    context "with more that 255 chars" do
      let(:login) { "a" * 256 }

      it "is valid" do
        user.login = login
        expect(user).to be_valid
      end

      it "may be loaded from the database" do
        user.login = login
        expect(user.save).to be_truthy

        expect(described_class.find_by_login(login)).to eq(user)
        expect(described_class.find_by_unique(login)).to eq(user)
      end
    end

    context "with an invalid login" do
      let(:login) { "me" }

      it "is invalid" do
        user.login = login
        expect(user).not_to be_valid
      end
    end

    context "with an overly long login (> 256 chars)" do
      let(:login) { "a" * 257 }

      it "is invalid" do
        expect(user).not_to be_valid
      end

      it "may not be stored in the database" do
        expect(user.save).to be_falsey
      end
    end

    context "with another user having the login in a different case" do
      let!(:other_user) { create(:user, login: "NewUser") }
      let(:login) { "newuser" }

      it "is invalid" do
        expect(user).not_to be_valid
      end
    end

    context "when empty" do
      let(:login) { "" }

      it "is invalid" do
        expect(user).not_to be_valid
      end
    end
  end

  describe "name validation" do
    let(:user) do
      build(:user)
    end

    it "restricts some options", :aggregate_failures do
      [
        "http://foobar.com",
        "<script>foobar</script>",
        "https://hello.com"
      ].each do |name|
        user.firstname = name
        user.lastname = name
        expect(user).not_to be_valid
        expect(user.errors.symbols_for(:firstname)).to eq [:invalid]
        expect(user.errors.symbols_for(:lastname)).to eq [:invalid]
      end
    end

    it "allows a lot of options", :aggregate_failures do
      [
        "Tim O'Reilly",
        "🔴Emojinames",
        "山本由紀夫",
        "Татьяна",
        "Users with spaces",
        "Müller, Phd.",
        "@invited+user.com",
        "Foo & Bar",
        "T’Oole"
      ].each do |name|
        user.firstname = name
        user.lastname = name
        expect(user).to be_valid
      end
    end
  end

  describe "#name" do
    before do
      create(:user,
             firstname: "John",
             lastname: "Smith",
             login: "username",
             mail: "user@name.org")
    end

    context "when formatting according to setting" do
      subject { user.name }

      let(:user) { described_class.select_for_name.last }

      context "for firstname_lastname", with_settings: { user_format: :firstname_lastname } do
        it { is_expected.to eq "John Smith" }
      end

      context "for firstname", with_settings: { user_format: :firstname } do
        it { is_expected.to eq "John" }
      end

      context "for lastname_firstname", with_settings: { user_format: :lastname_firstname } do
        it { is_expected.to eq "Smith John" }
      end

      context "for lastname_n_firstname", with_settings: { user_format: :lastname_n_firstname } do
        it { is_expected.to eq "SmithJohn" }
      end

      context "for lastname_coma_firstname", with_settings: { user_format: :lastname_coma_firstname } do
        it { is_expected.to eq "Smith, John" }
      end

      context "for username", with_settings: { user_format: :username } do
        it { is_expected.to eq "username" }
      end

      context "for nil", with_settings: { user_format: nil } do
        it { is_expected.to eq "John Smith" }
      end
    end

    context "when specifying format explicitly" do
      subject { user.name(formatter) }

      let(:user) { described_class.select_for_name(formatter).last }

      context "for lastname_coma_firstname" do
        let(:formatter) { :lastname_coma_firstname }

        it { is_expected.to eq "Smith, John" }
      end

      context "for username", with_settings: { user_format: :username } do
        let(:formatter) { :username }

        it { is_expected.to eq "username" }
      end
    end
  end

  describe "#authentication_provider" do
    before do
      user.identity_url = "test_provider:veryuniqueid"
      user.save!
    end

    it "creates a human readable name" do
      expect(user.authentication_provider).to eql("Test Provider")
    end
  end

  describe "#blocked" do
    let!(:blocked_user) do
      create(:user,
             failed_login_count: 3,
             last_failed_login_on: Time.zone.now)
    end

    before do
      user.save!
      allow(Setting).to receive(:brute_force_block_after_failed_logins).and_return(3)
      allow(Setting).to receive(:brute_force_block_minutes).and_return(30)
    end

    it "returns the single blocked user" do
      expect(described_class.blocked.length).to eq(1)
      expect(described_class.blocked.first.id).to eq(blocked_user.id)
    end
  end

  describe "#change_password_allowed?" do
    let(:user) { build(:user) }

    context "for user without auth source" do
      before do
        user.ldap_auth_source = nil
      end

      it "is true" do
        assert user.change_password_allowed?
      end
    end

    context "for user with an auth source" do
      let(:auth_source) { create(:ldap_auth_source) }

      before do
        user.ldap_auth_source = auth_source
      end

      it "does not allow password changes" do
        expect(user).not_to be_change_password_allowed
      end
    end

    context "for user without LdapAuthSource and with external authentication" do
      before do
        user.ldap_auth_source = nil
        allow(user).to receive(:uses_external_authentication?).and_return(true)
      end

      it "does not allow a password change" do
        expect(user).not_to be_change_password_allowed
      end
    end
  end

  describe "#watches" do
    before do
      user.save!
    end

    describe "WHEN the user is watching" do
      let(:watcher) do
        Watcher.new(watchable: issue,
                    user:)
      end

      before do
        issue.save!
        member.save!
        user.reload # the user object needs to know of its membership for the watcher to be valid
        watcher.save!
      end

      it { expect(user.watches).to eq([watcher]) }
    end

    describe "WHEN the user isn't watching" do
      before do
        issue.save!
      end

      it { expect(user.watches).to eq([]) }
    end
  end

  describe "#uses_external_authentication?" do
    context "with identity_url" do
      let(:user) { build(:user, identity_url: "test_provider:veryuniqueid") }

      it "returns true" do
        expect(user).to be_uses_external_authentication
      end
    end

    context "without identity_url" do
      let(:user) { build(:user, identity_url: nil) }

      it "returns false" do
        expect(user).not_to be_uses_external_authentication
      end
    end
  end

  describe "user create with empty password" do
    let(:user) { described_class.new(firstname: "new", lastname: "user", mail: "newuser@somenet.foo") }

    before do
      user.login = "new_user"
      user.password = ""
      user.password_confirmation = ""
      user.save
    end

    it { expect(user).not_to be_valid }

    it {
      expect(user.errors[:password]).to include I18n.t("activerecord.errors.messages.too_short",
                                                       count: Setting.password_min_length.to_i)
    }
  end

  describe "#random_password" do
    let(:user) { described_class.new }

    context "without generation" do
      it { expect(user.password).to be_nil }
      it { expect(user.password_confirmation).to be_nil }
    end

    context "with generation" do
      before do
        user.random_password!
      end

      it { expect(user.password).not_to be_blank }
      it { expect(user.password_confirmation).not_to be_blank }
      it { expect(user.force_password_change).to be_truthy }
    end
  end

  describe "#try_authentication_for_existing_user" do
    def build_user_double_with_expired_password(is_expired)
      user_double = double("User")
      allow(user_double).to receive(:check_password?).and_return(true)
      allow(user_double).to receive(:active?).and_return(true)
      allow(user_double).to receive(:ldap_auth_source).and_return(nil)
      allow(user_double).to receive(:force_password_change).and_return(false)

      # check for expired password should always happen
      expect(user_double).to receive(:password_expired?) { is_expired }

      user_double
    end

    it "does not allow login with an expired password" do
      user_double = build_user_double_with_expired_password(true)

      # use !! to ensure value is boolean
      expect(!!described_class.try_authentication_for_existing_user(user_double, "anypassword")).to \
        be(false)
    end

    it "allows login with a not expired password" do
      user_double = build_user_double_with_expired_password(false)

      # use !! to ensure value is boolean
      expect(!!described_class.try_authentication_for_existing_user(user_double, "anypassword")).to \
        be(true)
    end

    context "with an external auth source" do
      let(:auth_source) { build(:ldap_auth_source) }
      let(:user_with_external_auth_source) do
        user = build(:user, login: "user")
        allow(user).to receive(:ldap_auth_source).and_return(auth_source)
        user
      end

      context "and successful external authentication" do
        before do
          expect(auth_source).to receive(:authenticate).with("user", "password").and_return(true)
        end

        it "succeeds" do
          expect(described_class.try_authentication_for_existing_user(user_with_external_auth_source, "password"))
            .to eq(user_with_external_auth_source)
        end
      end

      context "and failing external authentication" do
        before do
          expect(auth_source).to receive(:authenticate).with("user", "password").and_return(false)
        end

        it "fails when the authentication fails" do
          expect(described_class.try_authentication_for_existing_user(user_with_external_auth_source, "password"))
            .to be_nil
        end
      end
    end
  end

  describe "#wants_comments_in_reverse_order?" do
    let(:user) { create(:user) }

    it "is false by default" do
      expect(user)
        .not_to be_wants_comments_in_reverse_order
    end

    it "is false if set to asc" do
      user.pref.comments_sorting = "asc"

      expect(user)
        .not_to be_wants_comments_in_reverse_order
    end

    it "is true if set to asc" do
      user.pref.comments_sorting = "desc"

      expect(user)
        .to be_wants_comments_in_reverse_order
    end
  end

  describe "#roles_for_project" do
    let(:project) { create(:project) }
    let!(:user) do
      create(:user,
             member_with_roles: { project => roles })
    end
    let(:roles) { create_list(:project_role, 2) }

    context "for a project the user has roles in" do
      it "returns the roles" do
        expect(user.roles_for_project(project))
          .to match_array roles
      end
    end

    context "for a project the user does not have roles in" do
      let(:other_project) { create(:project) }

      it "returns an empty set" do
        expect(user.roles_for_project(other_project))
          .to be_empty
      end
    end
  end

  describe "#roles_for_work_package" do
    let(:work_package) { create(:work_package) }
    let!(:user) do
      create(:user,
             member_with_roles: {
               work_package.project => project_roles,
               work_package => work_package_roles
             })
    end
    let(:project_roles) { create_list(:project_role, 2) }
    let(:work_package_roles) { create_list(:work_package_role, 1) }

    context "for a work_package the user has roles in" do
      it "returns the roles" do
        expect(user.roles_for_work_package(work_package))
          .to match_array project_roles + work_package_roles
      end
    end

    context "for a work_package the user does not have roles in" do
      let(:other_work_package) { create(:work_package) }

      it "returns an empty set" do
        expect(user.roles_for_work_package(other_work_package))
          .to be_empty
      end
    end
  end

  describe ".system" do
    context "no SystemUser exists" do
      before do
        SystemUser.delete_all
      end

      it "creates a SystemUser" do
        expect do
          system_user = described_class.system
          expect(system_user).not_to be_new_record
          expect(system_user).to be_a(SystemUser)
        end.to change(described_class, :count).by(1)
      end
    end

    context "a SystemUser exists" do
      before do
        @u = described_class.system
        expect(SystemUser.first).to eq(@u)
      end

      it "returns existing SystemUser" do
        expect do
          system_user = described_class.system
          expect(system_user).to eq(@u)
        end.not_to change(described_class, :count)
      end
    end
  end

  describe ".default_admin_account_deleted_or_changed?" do
    let(:default_admin) do
      build(:user, login: "admin", password: "admin", password_confirmation: "admin", admin: true)
    end

    before do
      Setting.password_min_length = 5
    end

    context "default admin account exists with default password" do
      before do
        default_admin.save
      end

      it { expect(described_class).not_to be_default_admin_account_changed }
    end

    context "default admin account exists with changed password" do
      before do
        default_admin.update_attribute :password, "dafaultAdminPwd"
        default_admin.update_attribute :password_confirmation, "dafaultAdminPwd"
        default_admin.save
      end

      it { expect(described_class).to be_default_admin_account_changed }
    end

    context "default admin account was deleted" do
      before do
        default_admin.save
        default_admin.delete
      end

      it { expect(described_class).to be_default_admin_account_changed }
    end

    context "default admin account was disabled" do
      before do
        default_admin.status = described_class.statuses[:locked]
        default_admin.save
      end

      it { expect(described_class).to be_default_admin_account_changed }
    end
  end

  describe ".find_by_rss_key" do
    let(:rss_key) { user.rss_key }

    context "feeds enabled" do
      before do
        allow(Setting).to receive(:feeds_enabled?).and_return(true)
      end

      it { expect(described_class.find_by_rss_key(rss_key)).to eq(user) }
    end

    context "feeds disabled" do
      before do
        allow(Setting).to receive(:feeds_enabled?).and_return(false)
      end

      it { expect(described_class.find_by_rss_key(rss_key)).to be_nil }
    end
  end

  describe "#rss_key" do
    let(:user) { create(:user) }

    it "is created on the fly" do
      expect { user.rss_key }
        .to change { user.reload.rss_token.nil? }
              .from(true)
              .to(false)
    end

    it "is persisted" do
      key = user.rss_key

      expect(user.reload.rss_key)
        .to eq key
    end

    it "has a length of 64" do
      expect(user.rss_key.length)
        .to eq 64
    end
  end

  describe "#ical_tokens" do
    let(:user) { create(:user) }
    let(:query) { create(:query, user:) }
    let(:ical_token) { create(:ical_token, user:, query:, name: "My Token") }
    let(:another_ical_token) { create(:ical_token, user:, query:, name: "My Other Token") }

    it "are not present by default" do
      expect(user.ical_tokens)
        .to be_empty
    end

    it "returns all existing ical tokens from this user" do
      ical_token
      another_ical_token

      expect(user.ical_tokens).to contain_exactly(ical_token, another_ical_token)
    end

    it "are destroyed when the user is destroyed" do
      ical_token
      another_ical_token

      user.destroy

      expect(Token::ICal.all).to be_empty
    end
  end

  describe ".newest" do
    let!(:anonymous) { described_class.anonymous }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    let(:newest) { described_class.newest.to_a }

    it "without anonymous user", :aggregate_failures do
      expect(newest).to include(user1)
      expect(newest).to include(user2)
      expect(newest).not_to include(anonymous)
    end
  end

  describe "#mail_regexp" do
    it "handles suffixed mails" do
      _, suffixed = described_class.mail_regexp("foo+bar@example.org")
      expect(suffixed).to be_truthy
    end
  end

  describe "#find_by_mail" do
    let!(:user1) { create(:user, mail: "foo+test@example.org") }
    let!(:user2) { create(:user, mail: "foo@example.org") }
    let!(:user3) { create(:user, mail: "foo-bar@example.org") }

    context "with default plus suffix" do
      it "finds users matching the suffix" do
        expect(Setting.mail_suffix_separators).to eq "+"

        # Can match either of the first two
        match2 = described_class.find_by_mail("foo@example.org")
        expect([user1.id, user2.id]).to include(match2.id)

        matches = described_class.where_mail_with_suffix("foo@example.org")
        expect(matches.pluck(:id)).to contain_exactly(user1.id, user2.id)

        matches = described_class.where_mail_with_suffix("foo+test@example.org")
        expect(matches.pluck(:id)).to contain_exactly(user1.id)
      end
    end

    context "with plus and minus suffix", with_settings: { mail_suffix_separators: "+-" } do
      it "finds users matching the suffix" do
        expect(Setting.mail_suffix_separators).to eq "+-"

        match1 = described_class.find_by_mail("foo-bar@example.org")
        expect(match1).to eq(user3)

        # Can match either of the three
        match2 = described_class.find_by_mail("foo@example.org")
        expect([user1.id, user2.id, user3.id]).to include(match2.id)

        matches = described_class.where_mail_with_suffix("foo@example.org")
        expect(matches.pluck(:id)).to contain_exactly(user1.id, user2.id, user3.id)
      end
    end
  end

  describe ".try_to_login" do
    let(:password) { "pwd123Password!" }
    let(:login) { "the_login" }
    let(:status) { described_class.statuses[:active] }

    let!(:user) do
      create(:user,
             password:,
             password_confirmation: password,
             login:,
             status:)
    end

    context "with good credentials" do
      it "returns the user" do
        expect(described_class.try_to_login(login, password))
          .to eq user
      end
    end

    context "with wrong password" do
      it "returns the user" do
        expect(described_class.try_to_login(login, "#{password}!"))
          .to be_nil
      end
    end

    context "with wrong case in login" do
      it "returns the user" do
        expect(described_class.try_to_login("The_login", password))
          .to eq user
      end
    end

    context "with wrong characters in login" do
      it "returns nil" do
        expect(described_class.try_to_login(login[0..-2], password))
          .to be_nil
      end
    end

    context "with the user being locked" do
      let(:status) { described_class.statuses[:locked] }

      it "returns nil" do
        expect(described_class.try_to_login(login, "#{password}!"))
          .to be_nil
      end
    end

    context "with the user's password being changed" do
      let(:new_password) { "newPWD12%abc" }

      before do
        user.password = new_password
        user.save!
      end

      it "returns the user" do
        expect(described_class.try_to_login(login, new_password))
          .to eq user
      end
    end
  end

  describe ".find_by_api_key" do
    let(:status) { described_class.statuses[:active] }

    let!(:user) do
      create(:user,
             status:)
    end
    let!(:token) do
      create(:api_token, user:)
    end

    context "if the right token is used" do
      it "returns the user" do
        expect(described_class.find_by_api_key(token.plain_value))
          .to eq user
      end
    end

    context "if it isn't the right user" do
      it "returns nil" do
        expect(described_class.find_by_api_key("#{token.value}abc"))
          .to be_nil
      end
    end

    context "if the right token is used but the user is locked" do
      let(:status) { described_class.statuses[:locked] }

      it "returns nil" do
        expect(described_class.find_by_api_key(token.plain_value))
          .to be_nil
      end
    end
  end

  describe ".find_by_mail" do
    let(:mail) { "the@mail.org" }
    let!(:user) { create(:user, mail:) }

    context "with the exact mail" do
      it "finds the user" do
        expect(described_class.find_by(mail:))
          .to eq user
      end
    end

    context "with the mail address in uppercase" do
      it "finds the user" do
        expect(described_class.find_by_mail(mail.upcase))
          .to eq user
      end
    end

    context "with a different mail address" do
      it "is nil" do
        expect(described_class.find_by_mail(mail[1..-2]))
          .to be_nil
      end
    end

    context "with a mail suffix in the address" do
      let(:mail) { "the+other@mail.org" }

      it "finds the user" do
        expect(described_class.find_by_mail("the@mail.org"))
          .to eq user
      end
    end
  end

  describe ".anonymous" do
    it "creates an anonymous user on the fly" do
      expect(described_class.anonymous)
        .to be_a(AnonymousUser)
    end

    it "creates a persisted record" do
      expect(described_class.anonymous)
        .to be_persisted
    end
  end

  it_behaves_like "creates an audit trail on destroy" do
    subject { create(:attachment) }
  end

  it_behaves_like "acts_as_customizable included" do
    let(:model_instance) { user }
    let(:custom_field) { create(:user_custom_field, :string) }
  end

  describe ".available_custom_fields" do
    let(:admin) { build_stubbed(:admin) }
    let(:user) { build_stubbed(:user) }

    shared_let(:user_cf) { create(:user_custom_field) }
    shared_let(:admin_user_cf) { create(:user_custom_field, admin_only: true) }

    context "for an admin" do
      current_user { admin }

      it "returns all fields including admin-only" do
        expect(user.available_custom_fields)
          .to contain_exactly(user_cf, admin_user_cf)
      end
    end

    context "for a member" do
      current_user { user }

      it "does not return admin-only field" do
        expect(user.available_custom_fields)
          .to contain_exactly(user_cf)
      end
    end
  end
end
