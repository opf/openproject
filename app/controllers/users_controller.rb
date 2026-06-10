# frozen_string_literal: true

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

class UsersController < ApplicationController
  include OpTurbo::ComponentStream
  include WorkingTimesAuthorization
  include Notifications::NotificationSettingsActions

  layout "admin"

  before_action :authorize_global, except: %i[show deletion_info destroy]

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :find_user, only: %i[show
                                     edit
                                     update
                                     update_reminders
                                     update_workdays
                                     update_email_alerts
                                     update_participating
                                     update_non_participating
                                     update_date_alerts
                                     new_project_settings
                                     create_project_settings
                                     edit_project_settings
                                     update_project_settings
                                     destroy_project_settings
                                     change_status_info
                                     change_status
                                     destroy
                                     deletion_info
                                     resend_invitation]
  # rubocop:enable Rails/LexicallyScopedActionFilter
  # should also contain destroy but post data can not be redirected
  before_action :require_login, only: [:deletion_info]
  before_action :authorize_for_user, only: [:destroy]
  before_action :check_if_deletion_allowed, only: %i[deletion_info
                                                     destroy]
  no_authorization_required! :show
  authorization_checked! :destroy, :deletion_info

  # Password confirmation helpers and actions
  include PasswordConfirmation

  before_action :check_password_confirmation, only: [:destroy]

  include Accounts::UserLimits

  before_action :enforce_user_limit, only: [:create]
  before_action -> { enforce_user_limit flash_now: true }, only: [:new]

  include SortHelper
  include CustomFieldsHelper
  include PaginationHelper
  include Queries::Loading

  before_action :load_query_or_deny_access, only: %i[index configure_view_modal]

  def index
    respond_to do |format|
      format.html
      format.turbo_stream { render_index_turbo_stream }
    end
  end

  def configure_view_modal
    respond_with_dialog Users::ConfigureViewModalComponent.new(query: @query)
  end

  def show
    if can_show_user?
      render layout: (can_manage_or_create_users? ? "admin" : "no_menu")
    else
      render_404
    end
  end

  def new
    @user = User.new(language: Setting.default_language)
    @contract = Users::CreateContract.new(@user, current_user)
  end

  def edit
    @membership ||= Member.new
    @individual_principal = @user
    @contract = Users::UpdateContract.new(@user, current_user)

    prepare_views_for_tab
  end

  def create # rubocop:disable Metrics/AbcSize
    call = Users::CreateService
           .new(user: current_user)
           .call(create_params)

    @user = call.result

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to(params[:continue] ? new_user_path : helpers.allowed_management_user_profile_path(@user))
    else
      @contract = Users::CreateContract.new(@user, current_user)
      render action: :new, status: :unprocessable_entity
    end
  end

  def update_email_alerts
    global_setting = @user.notification_settings.find_or_initialize_by(project: nil)
    persist_notification_setting(global_setting, permitted_params.notification_setting_email_alerts)
    redirect_back_or_to edit_user_path(@user, tab: "reminders")
  end

  def update_reminders
    call = ::Users::UpdateService.new(model: @user, user: current_user).call(pref: permitted_params.pref.to_h)
    flash[call.success? ? :notice : :error] = update_service_flash_message(call)
    redirect_back_or_to edit_user_path(@user, tab: "reminders")
  end

  def update_participating
    update_user_notification_setting(permitted_params.notification_setting_participating)
  end

  def update_non_participating
    update_user_notification_setting(permitted_params.notification_setting_non_participating)
  end

  def update_date_alerts
    update_user_notification_setting(build_date_alerts_params)
  end

  def update # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    update_params = build_user_update_params
    call = ::Users::UpdateService.new(model: @user, user: current_user).call(update_params)

    if call.success?
      if update_params[:password].present? && @user.change_password_allowed?
        send_information = params[:send_information]

        if @user.invited?
          # setting a password for an invited user activates them implicitly
          if OpenProject::Enterprise.user_limit_reached?
            @user.register!
            show_user_limit_warning!
          else
            @user.activate!
          end

          send_information = true
        end

        if @user.active? && send_information
          UserMailer.account_information(@user, update_params[:password]).deliver_later
        end
      end

      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to action: :edit
        end
      end
    else
      @membership ||= Member.new
      # Clear password input
      @user = call.result
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html do
          @contract = Users::UpdateContract.new(@user, current_user)
          render action: :edit, status: :unprocessable_entity
        end
      end
    end
  end

  def change_status_info
    @status_change = params[:change_action].to_sym

    render_400 unless %i(activate lock unlock).include? @status_change
  end

  def change_status # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    if @user.id == current_user.id
      # user is not allowed to change own status
      flash[:error] = I18n.t("user.error_status_change_self")
      redirect_back_or_default({ action: "edit", id: @user })
      return
    end

    if @user.admin? && !current_user.admin?
      # non-admin users are not allowed to change admin status
      flash[:error] = I18n.t("user.error_admin_change_on_non_admin")
      redirect_back_or_default({ action: "edit", id: @user })
      return
    end

    if (params[:unlock] || params[:activate]) && user_limit_reached?
      show_user_limit_error!

      return redirect_back_or_default({ action: "edit", id: @user })
    end

    activated_account = false

    if params[:unlock]
      @user.failed_login_count = 0
      @user.activate
      activated_account = true
    elsif params[:lock]
      @user.lock
    elsif params[:activate]
      @user.activate
      activated_account = true
    end

    # Was the account activated? (do it before User#save clears the change)
    should_deliver_activation_mail = (@user.status_change == %w[registered active])

    if activated_account && @user.missing_authentication_method?
      flash[:error] = I18n.t("user.error_status_change_failed",
                             errors: I18n.t(:notice_user_missing_authentication_method))
    elsif @user.save
      flash[:notice] = I18n.t(:notice_successful_update)
      if should_deliver_activation_mail
        UserMailer.account_activated(@user).deliver_later
      end
    else
      flash[:error] = I18n.t("user.error_status_change_failed",
                             errors: @user.errors.full_messages.join(", "))
    end
    redirect_back_or_default({ action: "edit", id: @user })
  end

  def resend_invitation # rubocop:disable Metrics/AbcSize
    if @user.admin? && !current_user.admin?
      # non-admin users are not allowed to change admin status
      flash[:error] = I18n.t("user.error_admin_change_on_non_admin")
      redirect_to helpers.allowed_management_user_profile_path(@user)
      return
    end

    status = Principal.statuses[:invited]
    @user.update!(status: status) if @user.status != status

    token = UserInvitation.reinvite_user @user.id

    if token.persisted?
      flash[:notice] = I18n.t(:notice_user_invitation_resent, email: @user.mail)
    else
      logger.error "could not re-invite #{@user.mail}: #{token.errors.full_messages.join(' ')}"
      flash[:error] = I18n.t(:notice_internal_server_error, app_title: Setting.app_title)
    end

    redirect_to helpers.allowed_management_user_profile_path(@user)
  end

  def destroy
    # true if the user deletes him/herself
    self_delete = (@user == User.current)

    result = Users::DeleteService.new(model: @user, user: User.current).call

    if result.success?
      flash[:notice] = I18n.t("account.deletion_pending")
    else
      flash[:error] = result.errors.full_messages.join(", ")
    end

    respond_to do |format|
      format.html do
        redirect_to self_delete ? signin_path : users_path
      end
    end
  end

  def deletion_info
    respond_with_dialog Users::DeleteDialogComponent.new(user: @user)
  end

  private

  def update_user_notification_setting(update_params)
    global_setting = @user.notification_settings.find_or_initialize_by(project: nil)
    persist_notification_setting(global_setting, update_params)
    redirect_back_or_to edit_user_path(@user, tab: "notifications")
  end

  def notifications_settings_path
    edit_user_path(@user, tab: "notifications")
  end

  def workdays_redirect_path
    edit_user_path(@user, tab: "reminders")
  end

  def project_notifications_create_url
    project_notifications_user_path(@user)
  end

  def project_setting_form_url(project_id)
    project_setting_user_path(@user, project_id:)
  end

  def can_show_user?
    return true if can_manage_or_create_users?
    return true if @user == User.current
    return true if current_user.allowed_globally?(:view_all_principals)

    return false unless @user.active? || @user.registered?

    @user.visible?(current_user)
  end

  def can_manage_or_create_users?
    current_user.allowed_globally?(:manage_user) || current_user.allowed_globally?(:create_user)
  end

  def find_user
    if params[:id] == User::CURRENT_USER_LOGIN_ALIAS || params[:id].nil?
      require_login || return
      @user = User.current
    else
      @user = User.visible.find(params[:id])
    end
  end

  def authorize_for_user
    if (User.current != @user ||
        User.current == User.anonymous) &&
       !User.current.admin?

      respond_to do |format|
        format.html { render_403 }
        format.xml  { head :unauthorized, "WWW-Authenticate" => 'Basic realm="OpenProject API"' }
        format.js   { head :unauthorized, "WWW-Authenticate" => 'Basic realm="OpenProject API"' }
        format.json { head :unauthorized, "WWW-Authenticate" => 'Basic realm="OpenProject API"' }
      end

      false
    end
  end

  def check_if_deletion_allowed
    return if Users::DeleteContract.deletion_allowed?(@user, User.current)

    render_error_flash_message_via_turbo_stream(message: I18n.t("user.error_cannot_delete_user"))
    respond_with_turbo_streams(status: :not_found) do |format|
      format.html { render_404 }
    end
  end

  def my_or_admin_layout
    # TODO: how can this be done better:
    # check if the route used to call the action is in the 'my' namespace
    if url_for(:delete_my_account_info) == request.url
      "my"
    else
      "admin"
    end
  end

  def set_password?(params)
    params[:user][:password].present? && !OpenProject::Configuration.disable_password_choice?
  end

  protected

  def build_user_update_params # rubocop:disable Metrics/AbcSize
    pref_params = permitted_params.pref.to_h
    update_params = permitted_params
      .user_create_as_admin(@user.uses_external_authentication?, @user.change_password_allowed?)
      .to_h
      .merge(pref: pref_params)

    return update_params unless @user.change_password_allowed?

    if params[:user][:assign_random_password]
      password = OpenProject::Passwords::Generator.random_password
      update_params.merge!(
        password:,
        password_confirmation: password,
        force_password_change: true
      )
    elsif set_password? params
      update_params[:password] = params[:user][:password]
      update_params[:password_confirmation] = params[:user][:password_confirmation]
      # Force a password change when the plain-text password will be emailed.
      # - For invited users, the account-information email is always sent
      # - For active users, it is only sent when the admin explicitly requests it.
      if params[:send_information].present? || @user.invited?
        update_params[:force_password_change] = true
      end
    end

    update_params
  end

  def create_params
    permitted_params
      .user_create_as_admin(false, false)
      .merge(admin: params[:user][:admin] || false,
             login: params[:user][:login] || params[:user][:mail],
             status: User.statuses[:invited])
  end

  def render_index_turbo_stream # rubocop:disable Metrics/AbcSize
    replace_via_turbo_stream(component: Users::IndexPageHeaderComponent.new(query: @query))
    update_via_turbo_stream(component: Users::UserFilterButtonComponent.new(query: @query))
    replace_via_turbo_stream(component: Users::TableComponent.new(rows: @query, current_user:))
    turbo_streams << turbo_stream.push_state(url_for(params.permit(:filters, :sortBy, :sort, :page, :per_page, :columns)))
    turbo_streams << turbo_stream.replace("primerized-flash-messages", helpers.render_flash_messages)
    render turbo_stream: turbo_streams
  end

  def prepare_views_for_tab # rubocop:disable Metrics/AbcSize
    if params[:tab] == "non_working_times"
      authorize_manage_working_times
      check_working_times_feature_flag_is_active

      @year = (params[:year].presence || Date.current.year).to_i
      @non_working_times = @user.non_working_time_entities_for_year(@year)
    elsif params[:tab] == "working_hours"
      authorize_manage_working_times
      check_working_times_feature_flag_is_active

      @current_working_hours = @user.working_hours.current

      @future_working_hours = @user.working_hours.upcoming(Date.current + 1)

      @past_working_hours = if @current_working_hours
                              @user.working_hours.history_for(@current_working_hours)
                            else
                              UserWorkingHours.none
                            end
    end
  end
end
