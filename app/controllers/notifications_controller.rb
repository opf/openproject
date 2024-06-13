#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class NotificationsController < ApplicationController
  before_action :require_login
  before_action :filtered_query, only: :mark_all_read
  no_authorization_required! :index, :mark_all_read

  def index
    # Frontend will handle rendering
    # but we will need to render with notification specific layout
    render layout: "angular/notifications"
  end

  def mark_all_read
    if filtered_query.valid?
      filtered_query.results.update_all(read_ian: true, updated_at: Time.zone.now)
    else
      flash[:error] = filtered_query.errors.full_messages.join(", ")
    end

    redirect_back fallback_location: notifications_path
  end

  private

  def filtered_query
    query = Queries::Notifications::NotificationQuery.new(user: current_user)
    query.where(:read_ian, "=", "f")

    case params[:filter]
    when "project"
      id = params[:name].to_i
      query.where(:project, "=", [id])
    when "reason"
      query.where(:reason, "=", [params[:name]])
    end

    @filtered_query = query
  end
end
