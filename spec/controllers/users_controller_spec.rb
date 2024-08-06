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
require "work_package"

RSpec.describe UsersController do
  shared_let(:admin) { create(:admin) }
  shared_let(:anonymous) { User.anonymous }

  shared_let(:user_password) { "bob!" * 4 }
  shared_let(:user) do
    create(:user,
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  describe "GET new" do
    context "without user limit reached" do
      before do
        as_logged_in_user admin do
          get :new
        end
      end

      it "is success" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the template" do
        expect(response)
          .to have_rendered("new")
      end

      it "have a user object initialized" do
        expect(assigns(:user))
          .to be_a(User)
      end
    end

    context "with user limit reached" do
      before do
        allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)
      end

      context "with fail fast" do
        before do
          allow(OpenProject::Enterprise).to receive(:fail_fast?).and_return(true)

          as_logged_in_user admin do
            get :new
          end
        end

        it "shows a user limit error" do
          expect(flash[:error]).to match /Adding additional users will exceed the current limit/i
        end

        it "redirects back to the user index" do
          expect(response).to redirect_to users_path
        end
      end

      context "without fail fast" do
        before do
          as_logged_in_user admin do
            get :new
          end
        end

        it "shows a user limit warning" do
          expect(flash[:warning]).to match /Adding additional users will exceed the current limit/i
        end

        it "shows the new user page" do
          expect(response).to render_template("users/new")
        end
      end
    end
  end

  describe "GET deletion_info" do
    let(:params) { { "id" => user.id.to_s } }

    context "when the current user is the requested user" do
      current_user { user }

      context "when the setting users_deletable_by_self is set to true",
              with_settings: { users_deletable_by_self: true } do
        before do
          get :deletion_info, params:
        end

        it { expect(response).to have_http_status(:success) }

        it "assigns @user to requested user" do
          expect(assigns(:user)).to eq(user)
        end

        it { expect(response).to render_template("deletion_info") }
      end

      context "when the setting users_deletable_by_self is set to false",
              with_settings: { users_deletable_by_self: false } do
        before do
          get :deletion_info, params:
        end

        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context "when the current user is the anonymous user" do
      current_user { anonymous }

      before do
        get :deletion_info, params:
      end

      it {
        expect(response).to redirect_to(controller: "account",
                                        action: "login",
                                        back_url: controller.url_for(controller: "users",
                                                                     action: "deletion_info"))
      }
    end

    context "when the current user is admin" do
      current_user { admin }

      context "when the setting users_deletable_by_admins is set to true",
              with_settings: { users_deletable_by_admins: true } do
        before do
          get :deletion_info, params:
        end

        it { expect(response).to have_http_status(:success) }

        it "assigns @user to requested user" do
          expect(assigns(:user)).to eq(user)
        end

        it { expect(response).to render_template("deletion_info") }
      end

      context "when the setting users_deletable_by_admins is set to false",
              with_settings: { users_deletable_by_admins: false } do
        before do
          get :deletion_info, params:
        end

        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe "POST resend_invitation" do
    let(:invited_user) { create(:invited_user) }

    context "without admin rights" do
      let(:normal_user) { create(:user) }

      before do
        as_logged_in_user normal_user do
          post :resend_invitation, params: { id: invited_user.id }
        end
      end

      it "returns 403 forbidden" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "with admin rights" do
      before do
        expect(ActionMailer::Base.deliveries).to be_empty

        as_logged_in_user admin do
          perform_enqueued_jobs do
            post :resend_invitation, params: { id: invited_user.id }
          end
        end
      end

      it "redirects back to the edit user page" do
        expect(response).to redirect_to edit_user_path(invited_user)
      end

      it "sends another activation email" do
        mail = ActionMailer::Base.deliveries.first.body.parts.first.body.to_s
        token = Token::Invitation.find_by user_id: invited_user.id

        expect(mail).to include "activate your account"
        expect(mail).to include token.value
      end
    end
  end

  describe "GET edit" do
    before do
      as_logged_in_user admin do
        get :edit, params: { id: user.id }
      end
    end

    it "is success" do
      expect(response)
        .to have_http_status(:ok)
    end

    it "renders the template" do
      expect(response)
        .to have_rendered("edit")
    end

    it "have a user object initialized" do
      expect(assigns(:user))
        .to eql user
    end
  end

  describe "POST destroy" do
    let(:base_params) { { "id" => user.id.to_s, back_url: my_account_path } }

    before do
      disable_flash_sweep
    end

    context "when the password confirmation is missing" do
      before do
        allow(Setting).to receive(:users_deletable_by_self?).and_return(true)

        as_logged_in_user user do
          post :destroy, params: base_params
        end
      end

      it do
        expect(response).to redirect_to(controller: "my", action: "account")
      end

      it { expect(flash[:error]).to eq(I18n.t(:notice_password_confirmation_failed)) }
    end

    context "when password confirmation is present" do
      let(:params) do
        base_params.merge(_password_confirmation: user_password)
      end

      context "when the current user is the requested one" do
        current_user { user }

        context "when the setting users_deletable_by_self is set to true",
                with_settings: { users_deletable_by_self: true } do
          before do
            post :destroy, params:
          end

          it do
            expect(response).to redirect_to(controller: "account", action: "login")
          end

          it { expect(flash[:notice]).to eq(I18n.t("account.deletion_pending")) }
        end

        context "when the setting users_deletable_by_self is set to false",
                with_settings: { users_deletable_by_self: false } do
          before do
            post :destroy, params:
          end

          it { expect(response).to have_http_status(:not_found) }
        end
      end

      context "when the current user is the anonymous user" do
        current_user { anonymous }

        context "even when the setting login_required is set to false and users_deletable_by_self is set to true",
                with_settings: { login_required: false, users_deletable_by_self: true } do
          before do
            post :destroy, params: params.merge(id: anonymous.id.to_s)
          end

          # redirecting post is not possible for now
          it { expect(response).to have_http_status(:forbidden) }
        end
      end

      context "when the current user is the admin" do
        current_user { admin }

        context "when the given password does NOT match and the setting users_deletable_by_admins is set to true",
                with_settings: { users_deletable_by_admins: true } do
          before do
            post :destroy, params:
          end

          it "redirects with error" do
            expect(response).to redirect_to(controller: "my", action: "account")
            expect(flash[:notice]).to be_nil
            expect(flash[:error]).to eq(I18n.t(:notice_password_confirmation_failed))
          end
        end

        context "when the given password does match and the setting users_deletable_by_admins is set to true",
                with_settings: { users_deletable_by_admins: true } do
          before do
            post :destroy, params: params.merge(_password_confirmation: "adminADMIN!")
          end

          it do
            expect(response).to redirect_to(controller: "users", action: "index")
          end

          it { expect(flash[:notice]).to eq(I18n.t("account.deletion_pending")) }
        end

        context "when the setting users_deletable_by_admins is set to false",
                with_settings: { users_deletable_by_admins: false } do
          before do
            post :destroy, params:
          end

          it { expect(response).to have_http_status(:not_found) }
        end
      end
    end
  end

  describe "#change_status_info" do
    let!(:registered_user) do
      create(:user, status: User.statuses[:registered])
    end

    before do
      as_logged_in_user admin do
        get :change_status_info,
            params: {
              id: registered_user.id,
              change_action:
            }
      end
    end

    shared_examples "valid status info" do
      it "renders the status info" do
        expect(response).to be_successful
        expect(response).to render_template "users/change_status_info"
        expect(assigns(:user)).to eq(registered_user)
        expect(assigns(:status_change)).to eq(change_action)
      end
    end

    describe "with valid activate" do
      let(:change_action) { :activate }

      it_behaves_like "valid status info"
    end

    describe "with valid unlock" do
      let(:change_action) { :unlock }

      it_behaves_like "valid status info"
    end

    describe "with valid lock" do
      let(:change_action) { :lock }

      it_behaves_like "valid status info"
    end

    describe "bogus status" do
      let(:change_action) { :wtf }

      it "renders 400" do
        expect(response).to have_http_status(:bad_request)
        expect(response).not_to render_template "users/change_status_info"
      end
    end
  end

  describe "#change_status",
           with_settings: {
             available_languages: %w[en de],
             bcc_recipients: 1
           } do
    describe "WHEN activating a registered user" do
      let!(:registered_user) do
        create(:user, status: User.statuses[:registered],
                      language: "de")
      end

      let(:user_limit_reached) { false }

      before do
        allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(user_limit_reached)

        as_logged_in_user admin do
          post :change_status,
               params: {
                 id: registered_user.id,
                 user: { status: User.statuses[:active] },
                 activate: "1"
               }
        end
      end

      it "activates the user" do
        assert registered_user.reload.active?
      end

      it "sends an email to the correct user in the correct language" do
        perform_enqueued_jobs
        mail = ActionMailer::Base.deliveries.last
        expect(mail).not_to be_nil
        expect([registered_user.mail]).to eq(mail.to)
        mail.parts.each do |part|
          expect(part.body.encoded).to include(I18n.t(:notice_account_activated, locale: "de"))
        end
      end

      context "with user limit reached" do
        let(:user_limit_reached) { true }

        it "shows the user limit reached error and recommends to upgrade" do
          expect(flash[:error]).to match /Adding additional users will exceed the current limit.*upgrade/i
        end

        it "does not activate the user" do
          expect(registered_user.reload).not_to be_active
        end
      end
    end
  end

  describe "GET #index" do
    let(:params) { {} }

    before do
      as_logged_in_user admin do
        get :index, params:
      end
    end

    it "to be success" do
      expect(response)
        .to have_http_status(:ok)
    end

    it "renders the index" do
      expect(response)
        .to have_rendered("index")
    end

    it "assigns users" do
      expect(assigns(:users))
        .to contain_exactly(user, admin)
    end

    context "with a name filter" do
      let(:params) { { name: user.firstname } }

      it "assigns users" do
        expect(assigns(:users))
          .to contain_exactly(user)
      end
    end

    context "with a group filter" do
      let(:group) { create(:group, members: [user]) }

      let(:params) do
        { group_id: group.id }
      end

      it "assigns users" do
        expect(assigns(:users))
          .to contain_exactly(user)
      end
    end
  end

  describe "session lifetime" do
    # TODO move this section to a proper place because we test a
    # before_action from the application controller

    after do
      # reset, so following tests are not affected by the change
      User.current = nil
    end

    shared_examples_for "index action with disabled session lifetime or inactivity not exceeded" do
      it "doesn't logout the user and renders the index action" do
        expect(User.current).to eq(admin)
        expect(response).to render_template "index"
      end
    end

    shared_examples_for "index action with enabled session lifetime and inactivity exceeded" do
      it "logs out the user and redirects with a warning that he has been locked out" do
        expect(response.redirect_url).to eq(signin_url + "?back_url=" + CGI::escape(@controller.url_for(controller: "users",
                                                                                                        action: "index")))
        expect(User.current).not_to eq(admin)
        expect(flash[:warning]).to eq(I18n.t(:notice_forced_logout, ttl_time: Setting.session_ttl))
      end
    end

    context "disabled" do
      before do
        allow(Setting).to receive(:session_ttl_enabled?).and_return(false)
        @controller.send(:logged_user=, admin)
        get :index
      end

      it_behaves_like "index action with disabled session lifetime or inactivity not exceeded"
    end

    context "enabled" do
      before do
        allow(Setting).to receive(:session_ttl_enabled?).and_return(true)
        allow(Setting).to receive(:session_ttl).and_return("120")
        @controller.send(:logged_user=, admin)
      end

      context "before 120 min of inactivity" do
        before do
          session[:updated_at] = Time.now - 1.hour
          get :index
        end

        it_behaves_like "index action with disabled session lifetime or inactivity not exceeded"
      end

      context "after 120 min of inactivity" do
        before do
          session[:updated_at] = Time.now - 3.hours
          get :index
        end

        it_behaves_like "index action with enabled session lifetime and inactivity exceeded"
      end

      context "without last activity time in the session" do
        before do
          allow(Setting).to receive(:session_ttl).and_return("60")
          session[:updated_at] = nil
          get :index
        end

        it_behaves_like "index action with enabled session lifetime and inactivity exceeded"
      end

      context "with ttl = 0" do
        before do
          allow(Setting).to receive(:session_ttl).and_return("0")
          session[:updated_at] = Time.now - 1.hour
          get :index
        end

        it_behaves_like "index action with disabled session lifetime or inactivity not exceeded"
      end

      context "with ttl < 0" do
        before do
          allow(Setting).to receive(:session_ttl).and_return("-60")
          session[:updated_at] = Time.now - 1.hour
          get :index
        end

        it_behaves_like "index action with disabled session lifetime or inactivity not exceeded"
      end

      context "with ttl < 5 > 0" do
        before do
          allow(Setting).to receive(:session_ttl).and_return("4")
          session[:updated_at] = Time.now - 1.hour
          get :index
        end

        it_behaves_like "index action with disabled session lifetime or inactivity not exceeded"
      end
    end
  end

  describe "PATCH #update" do
    shared_let(:user_with_manage_user_global_permission) do
      create(:user, login: "human-resources", global_permissions: [:manage_user])
    end
    shared_let(:some_user) { create(:user, firstname: "User being updated") }
    shared_let(:some_admin) { create(:admin, firstname: "Admin being updated") }

    context "when updating fields as an admin" do
      current_user { admin }

      let(:params) do
        {
          id: some_user.id,
          user: {
            firstname: "Changed",
            login: "changed_login",
            force_password_change: true
          },
          pref: {
            hide_mail: "1",
            comments_sorting: "desc"
          }
        }
      end

      before do
        perform_enqueued_jobs do
          put :update, params:
        end
      end

      it "redirects to the edit page" do
        expect(response).to render_template :edit
      end

      it "is assigned their new values" do
        some_user_from_db = User.find(some_user.id)
        expect(some_user_from_db.firstname).to eq("Changed")
        expect(some_user_from_db.login).to eq("changed_login")
        expect(some_user_from_db.force_password_change).to be(true)
        expect(some_user_from_db.pref[:hide_mail]).to be_truthy
        expect(some_user_from_db.pref[:comments_sorting]).to eq("desc")
      end

      it "sends no mail" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      context "when updating the password" do
        let(:params) do
          {
            id: some_user.id,
            user: { password: "newpassPASS!",
                    password_confirmation: "newpassPASS!" },
            send_information: "1"
          }
        end

        it "sends an email to the user with the password in it" do
          mail = ActionMailer::Base.deliveries.last

          expect(mail.to)
            .to contain_exactly(some_user.mail)

          expect(mail.body.encoded)
            .to include("newpassPASS!")
        end
      end

      context "with invalid params" do
        let(:params) do
          {
            id: some_user.id,
            user: {
              firstname: ""
            }
          }
        end

        it "is success" do
          expect(response)
            .to have_http_status(:ok)
        end

        it "renders the edit template with errors" do
          expect(response)
            .to have_rendered("edit")
          expect(assigns(:user).errors.first)
            .to have_attributes(attribute: :firstname, type: :blank)
        end
      end
    end

    shared_examples "it can update field" do |field:, value:, edited_user:, current_user:|
      it "can change field #{field} " \
         "of #{edited_user.to_s.humanize(capitalize: false)} " \
         "as #{current_user.to_s.humanize(capitalize: false)}" do
        login_as send(current_user)
        params = {
          id: send(edited_user).id,
          user: {
            field => value
          }
        }
        expect { put :update, params: }
          .to change { send(edited_user).reload.send(field) }
          .to(value)
      end
    end

    shared_examples "it cannot update field" do |field:, value:, edited_user:, current_user:|
      it "cannot change field #{field} " \
         "of #{edited_user.to_s.humanize(capitalize: false)} " \
         "as #{current_user.to_s.humanize(capitalize: false)}" do
        login_as send(current_user)
        params = {
          id: send(edited_user).id,
          user: {
            field => value
          }
        }

        expect { put :update, params: }
          .not_to change { send(edited_user).reload.send(field) }
      end
    end

    # admin field
    include_examples "it can update field",
                     field: :admin,
                     value: true,
                     edited_user: :some_user,
                     current_user: :admin
    include_examples "it can update field",
                     field: :admin,
                     value: false,
                     edited_user: :some_admin,
                     current_user: :admin
    include_examples "it cannot update field",
                     field: :admin,
                     value: true,
                     edited_user: :some_user,
                     current_user: :user
    include_examples "it cannot update field",
                     field: :admin,
                     value: true,
                     edited_user: :some_user,
                     current_user: :user_with_manage_user_global_permission

    # email field
    include_examples "it can update field",
                     field: :mail,
                     value: "another_email@example.com",
                     edited_user: :some_user,
                     current_user: :admin
    include_examples "it can update field",
                     field: :mail,
                     value: "another_email@example.com",
                     edited_user: :some_admin,
                     current_user: :admin
    include_examples "it can update field",
                     field: :mail,
                     value: "another_email@example.com",
                     edited_user: :some_user,
                     current_user: :user_with_manage_user_global_permission
    include_examples "it cannot update field",
                     field: :mail,
                     value: "another_email@example.com",
                     edited_user: :some_admin,
                     current_user: :user_with_manage_user_global_permission
    include_examples "it cannot update field",
                     field: :mail,
                     value: "another_email@example.com",
                     edited_user: :some_user,
                     current_user: :user

    context "with external authentication" do
      let(:some_user) { create(:user, identity_url: "some:identity") }

      before do
        as_logged_in_user(admin) do
          put :update, params: { id: some_user.id, user: { force_password_change: "true" } }
        end
        some_user.reload
      end

      it "ignores setting force_password_change" do
        expect(some_user.force_password_change).to be(false)
      end
    end

    context "with ldap auth source" do
      let(:ldap_auth_source) { create(:ldap_auth_source) }

      it "switching to internal authentication on a password change" do
        some_user.ldap_auth_source = ldap_auth_source
        as_logged_in_user admin do
          put :update,
              params: {
                id: some_user.id,
                user: { ldap_auth_source_id: "", password: "newpassPASS!",
                        password_confirmation: "newpassPASS!" }
              }
        end

        expect(some_user.reload.ldap_auth_source).to be_nil
        expect(some_user.check_password?("newpassPASS!")).to be true
      end
    end

    context "with disabled_password_choice",
            with_config: { disable_password_choice: true } do
      it "ignores password parameters and leaves the password unchanged" do
        as_logged_in_user(admin) do
          put :update,
              params: {
                id: user.id,
                user: { password: "changedpass!", password_confirmation: "changedpass!" }
              }
        end

        expect(user.reload.check_password?("changedpass!")).to be false
      end
    end
  end

  describe "Anonymous should not be able to create a user" do
    it "redirects to the login page" do
      post :create,
           params: {
             user: {
               login: "psmith",
               firstname: "Paul",
               lastname: "Smith"
             },
             password: "psmithPSMITH09",
             password_confirmation: "psmithPSMITH09"
           }
      expect(response).to redirect_to "/login?back_url=http%3A%2F%2Ftest.host%2Fusers"
    end
  end

  describe "GET #show" do
    describe "general" do
      let(:current_user) { user }
      let(:params) { { id: user.id } }
      let(:action) { :show }

      before do
        as_logged_in_user current_user do
          get action, params:
        end
      end

      it "responds with success", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to render_template "show"
        expect(assigns(:user)).to eq(user)
      end

      context 'when requesting special value "me"' do
        let(:params) { { id: "me" } }

        it "responds with success", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to render_template "show"
          expect(assigns(:user)).to eq(user)
        end
      end

      context "when not being logged in" do
        let(:current_user) { User.anonymous }

        context "when login_required", with_settings: { login_required: true } do
          it "redirects to login" do
            expect(response).to redirect_to signin_path(back_url: user_url(user.id))
          end
        end

        context "when not login_required", with_settings: { login_required: false } do
          it "responds with 200" do
            expect(response)
              .to have_http_status(:ok)
          end
        end

        context 'when requesting special value "me"' do
          let(:params) { { id: "me" } }

          it "redirects to login", :aggregate_failures do
            expect(response).to redirect_to signin_url(back_url: user_url("me"))
          end
        end
      end

      context "when the user is locked for an admin" do
        let(:current_user) do
          user.locked!
          admin
        end

        it "responds with 200" do
          expect(response)
            .to have_http_status(:ok)
        end
      end

      context "when the user is locked for an non admin" do
        let(:current_user) do
          user.locked!
          create(:user)
        end

        it "responds with 200" do
          expect(response)
            .to have_http_status(:not_found)
        end
      end
    end

    describe "for user with Activity" do
      render_views

      let(:work_package) do
        create(:work_package,
               author: user)
      end
      let!(:member) do
        create(:member,
               project: work_package.project,
               principal: user,
               roles: [create(:project_role,
                              permissions: [:view_work_packages])])
      end
      let!(:journal_1) do
        create(:work_package_journal,
               user:,
               journable_id: work_package.id,
               version: Journal.maximum(:version) + 1,
               data: build(:journal_work_package_journal,
                           subject: work_package.subject,
                           status_id: work_package.status_id,
                           type_id: work_package.type_id,
                           project_id: work_package.project_id))
      end
      let!(:journal_2) do
        create(:work_package_journal,
               user:,
               journable_id: work_package.id,
               version: Journal.maximum(:version) + 1,
               data: build(:journal_work_package_journal,
                           subject: work_package.subject,
                           status_id: work_package.status_id,
                           type_id: work_package.type_id,
                           project_id: work_package.project_id))
      end

      before do
        allow(User).to receive(:current).and_return(user.reload)
        allow_any_instance_of(User).to receive(:reported_work_package_count).and_return(42)

        get :show, params: { id: user.id }
      end

      it "includes the number of reported work packages" do
        label = Regexp.escape(I18n.t(:label_reported_work_packages))

        expect(response.body).to have_css("p", text: /#{label}.*42/)
      end
    end
  end

  describe "POST #create" do
    current_user { admin }

    let(:params) do
      {
        user: {
          firstname: "John",
          lastname: "Doe",
          login: "jdoe",
          password: "adminADMIN!",
          password_confirmation: "adminADMIN!",
          mail: "jdoe@gmail.com"
        },
        pref: {}
      }
    end

    before do
      perform_enqueued_jobs do
        post :create, params:
      end
    end

    it "is successful" do
      expect(response)
        .to redirect_to edit_user_path(User.newest.first)
    end

    it "creates the user with the provided params" do
      expect(User.newest.first.attributes.with_indifferent_access.slice(:firstname, :lastname, :login, :mail))
        .to eql params[:user].with_indifferent_access.slice(:firstname, :lastname, :login, :mail)
    end

    it "sends an activation mail" do
      mail = ActionMailer::Base.deliveries.last

      expect(mail.to)
        .to contain_exactly(params[:user][:mail])

      activation_link = Regexp.new(
        "http://#{Setting.host_name}/account/activate\\?token=[a-f0-9]+",
        Regexp::MULTILINE
      )

      assert(mail.body.encoded =~ activation_link)
    end

    context "with invalid parameters" do
      let(:params) { { user: { login: "jdoe" } } }

      it "renders new" do
        expect(response)
          .to render_template "new"
      end
    end
  end
end
