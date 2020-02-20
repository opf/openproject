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

class Users::MembershipsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_user

  def update
    update_or_create(request.patch?, :notice_successful_update)
  end

  def create
    update_or_create(request.post?, :notice_successful_create)
  end

  def destroy
    @membership = @user.memberships.find(params[:id])

    if @membership.deletable? && request.delete?
      @membership.destroy && @membership = nil
      flash[:notice] = I18n.t(:notice_successful_delete)
    end

    redirect_to controller: '/users', action: 'edit', id: @user, tab: 'memberships'
  end

  private

  def update_or_create(save_record, message)
    @membership = params[:id].present? ? Member.find(params[:id]) : Member.new(principal: @user)
    service = ::Members::EditMembershipService.new(@membership, save: save_record, current_user: current_user)
    result = service.call(attributes: permitted_params.membership)

    if result.success?
      flash[:notice] = I18n.t(message)
    else
      flash[:error] = result.errors.full_messages.join("\n")
    end
    redirect_to controller: '/users', action: 'edit', id: @user, tab: 'memberships'
  end

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
