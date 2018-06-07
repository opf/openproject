#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'work_package'

describe UsersController, type: :controller do
  before do
    User.delete_all
  end

  after do
    User.current = nil
  end

  let(:user_password) {'bob!' * 4}
  let(:user) do
    FactoryGirl.create(:user,
                       login: 'bob',
                       password: user_password,
                       password_confirmation: user_password,
                       )
  end
  let(:admin) { FactoryGirl.create(:admin) }
  let(:anonymous) { FactoryGirl.create(:anonymous) }

  describe 'GET new' do
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
          expect(flash[:error]).to match /user limit reached/i
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
          expect(flash[:warning]).to match /user limit reached/i
        end

        it "shows the new user page" do
          expect(response).to render_template("users/new")
        end
      end
    end
  end

  describe 'GET deletion_info' do
    describe "WHEN the current user is the requested user
              WHEN the setting users_deletable_by_self is set to true" do
      let(:params) { { 'id' => user.id.to_s } }

      before do
        allow(Setting).to receive(:users_deletable_by_self?).and_return(true)

        as_logged_in_user user do
          get :deletion_info, params: params
        end
      end

      it do expect(response).to be_success end
      it do expect(assigns(:user)).to eq(user) end
      it { expect(response).to render_template('deletion_info') }
    end

    describe "WHEN the current user is the requested user
              WHEN the setting users_deletable_by_self is set to false" do
      let(:params) { { 'id' => user.id.to_s } }

      before do
        allow(Setting).to receive(:users_deletable_by_self?).and_return(false)

        as_logged_in_user user do
          get :deletion_info, params: params
        end
      end

      it { expect(response.response_code).to eq(404) }
    end

    describe 'WHEN the current user is the anonymous user' do
      let(:params) { { 'id' => anonymous.id.to_s } }

      before do
        as_logged_in_user anonymous do
          get :deletion_info, params: params
        end
      end

      it {
        expect(response).to redirect_to(controller: 'account',
                                        action: 'login',
                                        back_url: @controller.url_for(controller: 'users',
                                                                      action: 'deletion_info'))
      }
    end

    describe "WHEN the current user is admin
              WHEN the setting users_deletable_by_admins is set to true" do
      let(:params) { { 'id' => user.id.to_s } }

      before do
        allow(Setting).to receive(:users_deletable_by_admins?).and_return(true)

        as_logged_in_user admin do
          get :deletion_info, params: params
        end
      end

      it do expect(response).to be_success end
      it do expect(assigns(:user)).to eq(user) end
      it { expect(response).to render_template('deletion_info') }
    end

    describe "WHEN the current user is admin
              WHEN the setting users_deletable_by_admins is set to false" do
      let(:params) { { 'id' => user.id.to_s } }

      before do
        allow(Setting).to receive(:users_deletable_by_admins?).and_return(false)

        as_logged_in_user admin do
          get :deletion_info, params: params
        end
      end

      it { expect(response.response_code).to eq(404) }
    end
  end

  describe 'POST resend_invitation' do
    let(:invited_user) { FactoryGirl.create :invited_user }

    context 'without admin rights' do
      let(:normal_user) { FactoryGirl.create :user }

      before do
        as_logged_in_user normal_user do
          post :resend_invitation, params: { id: invited_user.id }
        end
      end

      it 'returns 403 forbidden' do
        expect(response.status).to eq 403
      end
    end

    context 'with admin rights' do
      let(:admin_user) { FactoryGirl.create :admin }

      before do
        expect(ActionMailer::Base.deliveries).to be_empty

        as_logged_in_user admin_user do
          post :resend_invitation, params: { id: invited_user.id }
        end
      end

      it 'redirects back to the edit user page' do
        expect(response).to redirect_to edit_user_path(invited_user)
      end

      it 'sends another activation email' do
        mail = ActionMailer::Base.deliveries.first.body.parts.first.body.to_s
        token = Token::Invitation.find_by user_id: invited_user.id

        expect(mail).to include 'activate your account'
        expect(mail).to include token.value
      end
    end
  end

  describe 'POST destroy' do
    let(:base_params) { { 'id' => user.id.to_s, back_url: my_account_path } }
    context 'WHEN the password confirmation is missing' do
      before do
        disable_flash_sweep
        allow(Setting).to receive(:users_deletable_by_self?).and_return(true)

        as_logged_in_user user do
          post :destroy, params: base_params
        end
      end

      it do expect(response).to redirect_to(controller: 'my', action: 'account') end
      it { expect(flash[:error]).to eq(I18n.t(:notice_password_confirmation_failed)) }
    end


    context 'WHEN password confirmation is present' do
      let(:base_params) do
        { 'id' => user.id.to_s, :'_password_confirmation' => user_password, back_url: my_account_path }
      end

      describe "WHEN the current user is the requested one
                WHEN the setting users_deletable_by_self is set to true" do
        before do
          disable_flash_sweep
          allow(Setting).to receive(:users_deletable_by_self?).and_return(true)

          as_logged_in_user user do
            post :destroy, params: base_params
          end
        end

        it do expect(response).to redirect_to(controller: 'account', action: 'login') end
        it { expect(flash[:notice]).to eq(I18n.t('account.deleted')) }
      end

      describe "WHEN the current user is the requested one
                WHEN the setting users_deletable_by_self is set to false" do

        before do
          disable_flash_sweep
          allow(Setting).to receive(:users_deletable_by_self?).and_return(false)

          as_logged_in_user user do
            post :destroy, params: base_params
          end
        end

        it { expect(response.response_code).to eq(404) }
      end

      describe "WHEN the current user is the anonymous user
                EVEN when the setting login_required is set to false" do

        before do
          allow(@controller).to receive(:find_current_user).and_return(anonymous)
          allow(Setting).to receive(:login_required?).and_return(false)

          as_logged_in_user anonymous do
            post :destroy, params: base_params.merge(id: anonymous.id.to_s)
          end
        end

        # redirecting post is not possible for now
        it { expect(response.response_code).to eq(403) }
      end

      describe "WHEN the current user is the admin
                WHEN the given password does not match
                WHEN the setting users_deletable_by_admins is set to true" do
        let(:admin) { FactoryGirl.create(:admin) }

        before do
          disable_flash_sweep
          allow(Setting).to receive(:users_deletable_by_admins?).and_return(true)

          as_logged_in_user admin do
            post :destroy, params: base_params
          end
        end

        it 'redirects with error' do
          expect(response).to redirect_to(controller: 'my', action: 'account')
          expect(flash[:notice]).to eq(nil)
          expect(flash[:error]).to eq(I18n.t(:notice_password_confirmation_failed))
        end
      end

      describe "WHEN the current user is the admin
                WHEN the given password does match
                WHEN the setting users_deletable_by_admins is set to true" do

        let(:admin_password) {'admin!' * 4}
        let(:admin) do
          FactoryGirl.create(:admin,
                             password: admin_password,
                             password_confirmation: admin_password)
        end

        before do
          disable_flash_sweep
          allow(Setting).to receive(:users_deletable_by_admins?).and_return(true)

          as_logged_in_user admin do
            post :destroy, params: base_params.merge(:'_password_confirmation' => admin_password)
          end
        end

        it do expect(response).to redirect_to(controller: 'users', action: 'index') end
        it { expect(flash[:notice]).to eq(I18n.t('account.deleted')) }
      end

      describe "WHEN the current user is the admin
                WHEN the setting users_deletable_by_admins is set to false" do
        let(:admin) { FactoryGirl.create(:admin) }

        before do
          disable_flash_sweep
          allow(Setting).to receive(:users_deletable_by_admins).and_return(false)

          as_logged_in_user admin do
            post :destroy, params: base_params
          end
        end

        it { expect(response.response_code).to eq(404) }
      end
    end
  end

  describe '#change_status_info' do
    let!(:registered_user) do
      FactoryGirl.create(:user, status: User::STATUSES[:registered])
    end

    before do
      as_logged_in_user admin do
        get :change_status_info,
            params: {
              id: registered_user.id,
              change_action: change_action
            }
      end
    end

    shared_examples 'valid status info' do
      it 'renders the status info' do
        expect(response).to be_success
        expect(response).to render_template 'users/change_status_info'
        expect(assigns(:user)).to eq(registered_user)
        expect(assigns(:status_change)).to eq(change_action)
      end
    end

    describe 'with valid activate' do
      let(:change_action) { :activate }
      it_behaves_like 'valid status info'
    end

    describe 'with valid unlock' do
      let(:change_action) { :unlock }
      it_behaves_like 'valid status info'
    end

    describe 'with valid lock' do
      let(:change_action) { :lock }
      it_behaves_like 'valid status info'
    end

    describe 'bogus status' do
      let(:change_action) { :wtf }
      it 'renders 400' do
        expect(response.status).to eq(400)
        expect(response).not_to render_template 'users/change_status_info'
      end
    end
  end

  describe '#change_status',
           with_settings: {
             available_languages: %i(en de),
             bcc_recipients: 1
           } do
    describe 'WHEN activating a registered user' do
      let!(:registered_user) do
        FactoryGirl.create(:user, status: User::STATUSES[:registered],
                                  language: 'de')
      end

      let(:user_limit_reached) { false }

      before do
        allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(user_limit_reached)

        as_logged_in_user admin do
          post :change_status,
               params: {
                 id: registered_user.id,
                 user: { status: User::STATUSES[:active] },
                 activate: '1'
               }
        end
      end

      it 'should activate the user' do
        assert registered_user.reload.active?
      end

      it 'should send an email to the correct user in the correct language' do
        mail = ActionMailer::Base.deliveries.last
        refute_nil mail
        assert_equal [registered_user.mail], mail.to
        mail.parts.each do |part|
          assert part.body.encoded.include?(I18n.t(:notice_account_activated,
                                                   locale: 'de'))
        end
      end

      context "with user limit reached" do
        let(:user_limit_reached) { true }

        it "shows the user limit reached error and recommends to upgrade" do
          expect(flash[:error]).to match /user limit reached.*upgrade/i
        end

        it "does not activate the user" do
          expect(registered_user.reload).not_to be_active
        end
      end
    end
  end

  describe 'index' do
    describe 'with session lifetime' do
      # TODO move this section to a proper place because we test a
      # before_action from the application controller

      after(:each) do
        # reset, so following tests are not affected by the change
        User.current = nil
      end

      shared_examples_for 'index action with disabled session lifetime or inactivity not exceeded' do
        it "doesn't logout the user and renders the index action" do
          expect(User.current).to eq(admin)
          expect(response).to render_template 'index'
        end
      end

      shared_examples_for 'index action with enabled session lifetime and inactivity exceeded' do
        it 'logs out the user and redirects with a warning that he has been locked out' do
          expect(response.redirect_url).to eq(signin_url + '?back_url=' + CGI::escape(@controller.url_for(controller: 'users', action: 'index')))
          expect(User.current).not_to eq(admin)
          expect(flash[:warning]).to eq(I18n.t(:notice_forced_logout, ttl_time: Setting.session_ttl))
        end
      end

      context 'disabled' do
        before do
          allow(Setting).to receive(:session_ttl_enabled?).and_return(false)
          @controller.send(:logged_user=, admin)
          get :index
        end

        it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
      end

      context 'enabled ' do
        before do
          allow(Setting).to receive(:session_ttl_enabled?).and_return(true)
          allow(Setting).to receive(:session_ttl).and_return('120')
          @controller.send(:logged_user=, admin)
        end

        context 'before 120 min of inactivity' do
          before do
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end

        context 'after 120 min of inactivity' do
          before do
            session[:updated_at] = Time.now - 3.hours
            get :index
          end
          it_should_behave_like 'index action with enabled session lifetime and inactivity exceeded'
        end

        context 'without last activity time in the session' do
          before do
            allow(Setting).to receive(:session_ttl).and_return('60')
            session[:updated_at] = nil
            get :index
          end
          it_should_behave_like 'index action with enabled session lifetime and inactivity exceeded'
        end

        context 'with ttl = 0' do
          before do
            allow(Setting).to receive(:session_ttl).and_return('0')
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end

        context 'with ttl < 0' do
          before do
            allow(Setting).to receive(:session_ttl).and_return('-60')
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end

        context 'with ttl < 5 > 0' do
          before do
            allow(Setting).to receive(:session_ttl).and_return('4')
            session[:updated_at] = Time.now - 1.hours
            get :index
          end

          it_should_behave_like 'index action with disabled session lifetime or inactivity not exceeded'
        end
      end
    end
  end

  describe 'update' do
    context 'fields' do
      let(:user) {
        FactoryGirl.create(:user, firstname: 'Firstname',
                                  admin: true,
                                  login: 'testlogin',
                                  mail_notification: 'all',
                                  force_password_change: false)
      }
      let(:params) {
        {
          id: user.id,
          user: {
            admin: false,
            firstname: 'Changed',
            login: 'changedlogin',
            mail_notification: 'only_assigned',
            force_password_change: true
          },
          pref: {
            hide_mail: '1',
            comments_sorting: 'desc'
          }
        }
      }

      before do
        as_logged_in_user(admin) do
          put :update, params: params
        end
      end

      it 'should redirect to the edit page' do
        expect(response).to redirect_to(edit_user_url(user))
      end

      it 'should be assigned their new values' do
        user_from_db = User.find(user.id)
        expect(user_from_db.admin).to be_falsey
        expect(user_from_db.firstname).to eql('Changed')
        expect(user_from_db.login).to eql('changedlogin')
        expect(user_from_db.mail_notification).to eql('only_assigned')
        expect(user_from_db.force_password_change).to eql(true)
        expect(user_from_db.pref[:hide_mail]).to be_truthy
        expect(user_from_db.pref[:comments_sorting]).to eql('desc')
      end

      it 'should not send an email' do
        expect(ActionMailer::Base.deliveries.empty?).to be_truthy
      end
    end

    context 'with external authentication' do
      let(:user) { FactoryGirl.create(:user, identity_url: 'some:identity') }

      before do
        as_logged_in_user(admin) do
          put :update, params: { id: user.id, user: { force_password_change: 'true' } }
        end
        user.reload
      end

      it 'should ignore setting force_password_change' do
        expect(user.force_password_change).to eql(false)
      end
    end

    context 'ldap auth source' do
      let(:ldap_auth_source) { FactoryGirl.create(:ldap_auth_source) }

      it 'switchting to internal authentication on a password change' do
        user.auth_source = ldap_auth_source
        as_logged_in_user admin do
          put :update,
              params: {
                id: user.id,
                user: { auth_source_id: '', password: 'newpassPASS!',
                        password_confirmation: 'newpassPASS!' }
              }
        end

        expect(user.reload.auth_source).to be_nil
        expect(user.check_password?('newpassPASS!')).to be_truthy
      end
    end

    context 'with disabled_password_choice' do
      before do
        expect(OpenProject::Configuration).to receive(:disable_password_choice?).and_return(true)
      end

      it 'ignores password parameters and leaves the password unchanged' do
        as_logged_in_user(admin) do
          put :update,
              params: {
                id: user.id,
                user: { password: 'changedpass!', password_confirmation: 'changedpass!' }
              }
        end

        expect(user.reload.check_password?('changedpass!')).to be false
      end
    end
  end

  describe 'Anonymous should not be able to create a user' do
    it 'should redirect to the login page' do
      post :create,
           params: {
             user: {
               login: 'psmith',
               firstname: 'Paul',
               lastname: 'Smith'
             },
             password: 'psmithPSMITH09',
             password_confirmation: 'psmithPSMITH09'
           }
      expect(response).to redirect_to '/login?back_url=http%3A%2F%2Ftest.host%2Fusers'
    end
  end

  describe 'show' do
    describe 'general' do
      before do
        as_logged_in_user user do
          get :show, params: { id: user.id }
        end
      end

      it 'responds with success' do
        expect(response).to be_success
      end

      it 'renders the show template' do
        expect(response).to render_template 'show'
      end

      it 'assigns @user' do
        expect(assigns(:user)).to eq(user)
      end
    end

    describe 'for user with Activity' do
      render_views

      let(:work_package) {
        FactoryGirl.create(:work_package,
                           author: user)
      }
      let!(:member) {
        FactoryGirl.create(:member,
                           project: work_package.project,
                           principal: user,
                           roles: [FactoryGirl.create(:role,
                                                      permissions: [:view_work_packages])])
      }
      let!(:journal_1) {
        FactoryGirl.create(:work_package_journal,
                           user: user,
                           journable_id: work_package.id,
                           version: Journal.maximum(:version) + 1,
                           data: FactoryGirl.build(:journal_work_package_journal,
                                                   subject: work_package.subject,
                                                   status_id: work_package.status_id,
                                                   type_id: work_package.type_id,
                                                   project_id: work_package.project_id))
      }
      let!(:journal_2) {
        FactoryGirl.create(:work_package_journal,
                           user: user,
                           journable_id: work_package.id,
                           version: Journal.maximum(:version) + 1,
                           data: FactoryGirl.build(:journal_work_package_journal,
                                                   subject: work_package.subject,
                                                   status_id: work_package.status_id,
                                                   type_id: work_package.type_id,
                                                   project_id: work_package.project_id))
      }

      before do
        allow(User).to receive(:current).and_return(user.reload)
        allow_any_instance_of(User).to receive(:reported_work_package_count).and_return(42)

        get :show, params: { id: user.id }
      end

      it 'should include the number of reported work packages' do
        label = Regexp.escape(I18n.t(:label_reported_work_packages))

        expect(response.body).to have_selector('p', text: /#{label}.*42/)
      end

      it 'should have @events_by_day grouped by day' do
        expect(assigns(:events_by_day).keys.first.class).to eq(Date)
      end

      it 'should have more than one event for today' do
        expect(assigns(:events_by_day).first.size).to be > 1
      end
    end
  end
end
