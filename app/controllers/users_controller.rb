#-- encoding: UTF-8
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

class UsersController < ApplicationController
  layout 'admin'

  before_action :disable_api
  before_action :require_admin, except: [:show, :deletion_info, :destroy]
  before_action :find_user, only: [:show,
                                   :edit,
                                   :update,
                                   :change_status_info,
                                   :change_status,
                                   :destroy,
                                   :deletion_info,
                                   :resend_invitation]
  # should also contain destroy but post data can not be redirected
  before_action :require_login, only: [:deletion_info]
  before_action :authorize_for_user, only: [:destroy]
  before_action :check_if_deletion_allowed, only: [:deletion_info,
                                                   :destroy]

  # Password confirmation helpers and actions
  include Concerns::PasswordConfirmation
  before_action :check_password_confirmation, only: [:destroy]

  include Concerns::UserLimits
  before_action :enforce_user_limit, only: [:create]
  before_action -> { enforce_user_limit flash_now: true }, only: [:new]

  accept_key_auth :index, :show, :create, :update, :destroy

  include SortHelper
  include CustomFieldsHelper
  include PaginationHelper

  def index
    @groups = Group.all.sort
    @status = Users::UserFilterCell.status_param params
    @users = Users::UserFilterCell.filter params

    respond_to do |format|
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  def show
    # show projects based on current user visibility
    @memberships = @user.memberships
                        .visible(current_user)

    events = Redmine::Activity::Fetcher.new(User.current, author: @user).events(nil, nil, limit: 10)
    @events_by_day = events.group_by { |e| e.event_datetime.to_date }

    unless User.current.admin?
      if !(@user.active? ||
         @user.registered?) ||
         (@user != User.current && @memberships.empty? && events.empty?)
        render_404
        return
      end
    end

    respond_to do |format|
      format.html do render layout: 'base' end
    end
  end

  def new
    @user = User.new(language: Setting.default_language,
                     mail_notification: Setting.default_notification_option)
    @auth_sources = AuthSource.all
  end

  verify method: :post, only: :create, render: { nothing: true, status: :method_not_allowed }
  def create
    @user = User.new(language: Setting.default_language,
                     mail_notification: Setting.default_notification_option)
    @user.attributes = permitted_params.user_create_as_admin(false, @user.change_password_allowed?)
    @user.admin = params[:user][:admin] || false
    @user.login = params[:user][:login] || @user.mail

    if UserInvitation.invite_user! @user
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_user_path : edit_user_path(@user))
        end
      end
    else
      @auth_sources = AuthSource.all

      respond_to do |format|
        format.html do render action: 'new' end
      end
    end
  end

  def edit
    @auth_sources = AuthSource.all
    @membership ||= Member.new
  end

  verify method: :put, only: :update, render: { nothing: true, status: :method_not_allowed }
  def update
    @user.attributes = permitted_params.user_update_as_admin(@user.uses_external_authentication?,
                                                             @user.change_password_allowed?)

    if @user.change_password_allowed?
      if params[:user][:assign_random_password]
        @user.random_password!
      elsif set_password? params
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
      end
    end

    pref_params = if params[:pref].present?
                    permitted_params.pref
                  else
                    {}
                  end

    if @user.save
      update_email_service = UpdateUserEmailSettingsService.new(@user)
      update_email_service.call(mail_notification: pref_params.delete(:mail_notification),
                                self_notified: params[:self_notified] == '1',
                                notified_project_ids: params[:notified_project_ids])

      @user.pref.attributes = pref_params
      @user.pref.save

      if !@user.password.blank? && @user.change_password_allowed?
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
          UserMailer.account_information(@user, @user.password).deliver_now
        end
      end

      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back(fallback_location: edit_user_path(@user))
        end
      end
    else
      @auth_sources = AuthSource.all
      @membership ||= Member.new
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html do
          render action: :edit
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    redirect_to controller: '/users', action: 'edit', id: @user
  end

  def change_status_info
    @status_change = params[:change_action].to_sym

    return render_400 unless %i(activate lock unlock).include? @status_change
  end

  def change_status
    if @user.id == current_user.id
      # user is not allowed to change own status
      redirect_back_or_default(action: 'edit', id: @user)
      return
    end

    if (params[:unlock] || params[:activate]) && user_limit_reached?
      show_user_limit_error!

      return redirect_back_or_default(action: 'edit', id: @user)
    end

    if params[:unlock]
      @user.failed_login_count = 0
      @user.activate
    elsif params[:lock]
      @user.lock
    elsif params[:activate]
      @user.activate
    end
    # Was the account activated? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUSES[:registered],
                                             User::STATUSES[:active]])

    if params[:activate] && @user.missing_authentication_method?
      flash[:error] = I18n.t(:error_status_change_failed,
                             errors: I18n.t(:notice_user_missing_authentication_method),
                             scope: :user)
    elsif @user.save
      flash[:notice] = I18n.t(:notice_successful_update)
      if was_activated
        UserMailer.account_activated(@user).deliver_now
      end
    else
      flash[:error] = I18n.t(:error_status_change_failed,
                             errors: @user.errors.full_messages.join(', '),
                             scope: :user)
    end
    redirect_back_or_default(action: 'edit', id: @user)
  end

  def resend_invitation
    status = Principal::STATUSES[:invited]
    @user.update status: status if @user.status != status

    token = UserInvitation.reinvite_user @user.id

    if token.persisted?
      flash[:notice] = I18n.t(:notice_user_invitation_resent, email: @user.mail)
    else
      logger.error "could not re-invite #{@user.mail}: #{token.errors.full_messages.join(' ')}"
      flash[:error] = I18n.t(:notice_internal_server_error, app_title: Setting.app_title)
    end

    redirect_to edit_user_path(@user)
  end

  def destroy
    # true if the user deletes him/herself
    self_delete = (@user == User.current)

    DeleteUserService.new(@user, User.current).call

    flash[:notice] = l('account.deleted')

    respond_to do |format|
      format.html do
        redirect_to self_delete ? signin_path : users_path
      end
    end
  end

  def deletion_info
    render action: 'deletion_info', layout: my_or_admin_layout
  end

  private

  def find_user
    if params[:id] == 'current' || params['id'].nil?
      require_login || return
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_for_user
    if (User.current != @user ||
        User.current == User.anonymous) &&
       !User.current.admin?

      respond_to do |format|
        format.html do render_403 end
        format.xml  do head :unauthorized, 'WWW-Authenticate' => 'Basic realm="OpenProject API"' end
        format.js   do head :unauthorized, 'WWW-Authenticate' => 'Basic realm="OpenProject API"' end
        format.json do head :unauthorized, 'WWW-Authenticate' => 'Basic realm="OpenProject API"' end
      end

      false
    end
  end

  def check_if_deletion_allowed
    render_404 unless DeleteUserService.deletion_allowed? @user, User.current
  end

  def my_or_admin_layout
    # TODO: how can this be done better:
    # check if the route used to call the action is in the 'my' namespace
    if url_for(:delete_my_account_info) == request.url
      'my'
    else
      'admin'
    end
  end

  def set_password?(params)
    params[:user][:password].present? && !OpenProject::Configuration.disable_password_choice?
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t('label_user_plural')
    else
      ActionController::Base.helpers.link_to(t('label_user_plural'), users_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end
