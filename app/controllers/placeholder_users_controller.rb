#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class PlaceholderUsersController < ApplicationController
  include EnterpriseTrialHelper
  layout 'admin'
  before_action :authorize_global, except: %i[show]

  before_action :find_placeholder_user, only: %i[show
                                                 edit
                                                 update
                                                 deletion_info
                                                 destroy]

  before_action :authorize_deletion, only: %i[deletion_info destroy]

  def index
    @placeholder_users = PlaceholderUsers::PlaceholderUserFilterComponent.query params

    respond_to do |format|
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  def show
    # show projects based on current user visibility.
    # But don't simply concatenate the .visible scope to the memberships
    # as .memberships has an include and an order which for whatever reason
    # also gets applied to the Project.allowed_to parts concatenated by a UNION
    # and an order inside a UNION is not allowed in postgres.
    @memberships = @placeholder_user
                     .memberships
                     .where(id: Member.visible(current_user))

    respond_to do |format|
      format.html { render layout: 'no_menu' }
    end
  end

  def new
    @placeholder_user = PlaceholderUsers::SetAttributesService
      .new(user: User.current,
           model: PlaceholderUser.new,
           contract_class: EmptyContract)
      .call({})
      .result
  end

  def edit
    @membership ||= Member.new
    @individual_principal = @placeholder_user
  end

  def create
    service = PlaceholderUsers::CreateService.new(user: User.current)
    service_result = service.call(permitted_params.placeholder_user)
    @placeholder_user = service_result.result

    if service_result.success?
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

  def update
    service_result = PlaceholderUsers::UpdateService
      .new(user: User.current,
           model: @placeholder_user)
      .call(permitted_params.placeholder_user)

    if service_result.success?
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

  def deletion_info
    respond_to :html
  end

  def destroy
    PlaceholderUsers::DeleteService
      .new(user: User.current, model: @placeholder_user)
      .call

    flash[:info] = I18n.t(:notice_deletion_scheduled)

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

  protected

  def authorize_deletion
    unless helpers.can_delete_placeholder_user?(@placeholder_user, current_user)
      render_403 message: I18n.t('placeholder_users.right_to_manage_members_missing')
    end
  end

  def default_breadcrumb
    if action_name == 'index'
      t('label_placeholder_user_plural')
    else
      ActionController::Base.helpers.link_to(t('label_placeholder_user_plural'),
                                             placeholder_users_path)
    end
  end

  def show_local_breadcrumb
    action_name != 'show'
  end
end
