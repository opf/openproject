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

class Users::MembershipsController < ApplicationController
  layout 'admin'

  before_action :disable_api
  before_action :require_admin
  before_action :find_user

  def update
    update_or_create(request.patch?)
  end

  def create
    update_or_create(request.post?)
  end

  def destroy
    @membership = @user.memberships.find(params[:id])

    if @membership.deletable? && request.delete?
      @membership.destroy && @membership = nil
    end

    respond_to do |format|
      format.html do
        redirect_to controller: '/users', action: 'edit', id: @user, tab: 'memberships'
      end

      format.js {}
    end
  end

  private

  def update_or_create(save_record)
    @membership = params[:id].present? ? Member.find(params[:id]) : Member.new(principal: @user)
    service = ::Members::EditMembershipService.new(@membership, save: save_record, current_user: current_user)
    service.call(attributes: permitted_params.membership)

    respond_to do |format|
      format.html do
        redirect_to controller: '/users', action: 'edit', id: @user, tab: 'memberships'
      end
      format.js { render 'update_or_create' }
    end
  end

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
