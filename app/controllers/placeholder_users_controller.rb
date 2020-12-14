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
                                               :destroy,
                                               :resend_invitation]
  before_action :check_if_deletion_allowed, only: [:destroy]

  def index
    @groups = Group.all.sort
    @placeholder_users = PlaceholderUsers::PlaceholderUserFilterCell.filter params

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

    if @placeholder_user.save
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_back(fallback_location: edit_placeholder_user_path(@placeholder_user))
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

  def destroy
    Users::DeleteService.new(@placeholder_user, User.current).call

    flash[:notice] = I18n.t('account.deleted')

    respond_to do |format|
      format.html do
        redirect_to placeholder_users_path
      end
    end
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

  protected

  def default_breadcrumb
    if action_name == 'index'
      t('label_placeholder_user_plural')
    else
      ActionController::Base.helpers.link_to(t('label_placeholder_user_plural'), placeholder_users_path)
    end
  end

  def show_local_breadcrumb
    current_user.admin?
  end
end
