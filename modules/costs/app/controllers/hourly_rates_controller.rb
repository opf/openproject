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

class HourlyRatesController < ApplicationController
  helper :users
  helper :sort
  include SortHelper

  helper :hourly_rates
  include HourlyRatesHelper

  before_action :find_project, only: %i[show]
  before_action :find_user, only: %i[show]

  # #show has its own authorization
  before_action :authorize, except: %i[show]
  no_authorization_required! :show

  # TODO: this should be an index
  def show
    return deny_access if @project.nil?
    return deny_access unless User.current.allowed_in_project?(:view_hourly_rates, @project)

    @rates = HourlyRate.for_principal(@user).in_project(@project).newest_first
    @current_rate = @user.current_rate(@project)
  end

  private

  def find_project
    @project = Project.visible.find(params.expect(:project_id))
  end

  # Rates hang off users and placeholder users alike, so the lookup is over
  # principals rather than users.
  def find_user
    @user = if params[:id].blank?
              User.current
            elsif @project
              Principal.with_rates.in_project(@project).find(params.expect(:id))
            else
              Principal.with_rates.find(params.expect(:id))
            end
  end
end
