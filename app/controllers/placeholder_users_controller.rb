#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class PlaceholderUsersController < ApplicationController
  layout 'admin'

  helper_method :gon

  before_action :require_admin, except: [:show, :deletion_info, :destroy]
  before_action :find_placeholder_user, only: [:show,
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

  def show
    # show projects based on current user visibility
    @memberships = @user.memberships
                        .visible(current_user)

    events = Activities::Fetcher.new(User.current, author: @user).events(nil, nil, limit: 10)
    @events_by_day = events.group_by { |e| e.event_datetime.to_date }

    if !User.current.admin? &&
       (!(@user.active? ||
       @user.registered?) ||
       (@user != User.current && @memberships.empty? && events.empty?))
      render_404
    else
      respond_to do |format|
        format.html { render layout: 'no_menu' }
      end
    end
  end

  def new
    @placeholder_user = PlaceholderUser.new
  end

  def create
    @placeholder_user = PlaceholderUser.new
    @placeholder_user.attributes = permitted_params.placeholder_user

    if @placeholder_user.save
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to(params[:continue] ? new_placeholder_user_path : edit_placeholder_user_path(@placeholder_user))
        end
      end
    else
      respond_to do |format|
        format.html do
          render action: :new
        end
      end
    end
  end

  def edit
    @membership ||= Member.new
  end

  def update
    @placeholder_user.attributes = permitted_params.placeholder_user

    if @user.save
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_back(fallback_location: edit_placeholder_user_path(@user))
        end
      end
    else
      @membership ||= Member.new

      respond_to do |format|
        format.html do
          render action: :edit
        end
      end
    end
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
        UserMailer.account_activated(@user).deliver_later
      end
    else
      flash[:error] = I18n.t(:error_status_change_failed,
                             errors: @user.errors.full_messages.join(', '),
                             scope: :user)
    end
    redirect_back_or_default(action: 'edit', id: @user)
  end


  def destroy
    # true if the user deletes him/herself
    self_delete = (@user == User.current)

    Users::DeleteService.new(@user, User.current).call

    flash[:notice] = I18n.t('account.deleted')

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

  def find_placeholder_user
    @placeholder_user = PlaceholderUser.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_if_deletion_allowed
    render_404 unless Users::DeleteService.deletion_allowed? @placeholder_user, User.current
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
    current_user.admin?
  end
end
