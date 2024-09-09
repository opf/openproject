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

class NotificationsController < ApplicationController
  include WorkPackages::WithSplitView

  before_action :require_login
  before_action :filtered_query, only: :mark_all_read
  no_authorization_required! :index, :split_view, :update_counter, :mark_all_read, :date_alerts, :share_upsale

  def index
    render_notifications_layout
  end

  def split_view
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render "work_packages/split_view", layout: false
        else
          render :index, layout: "notifications"
        end
      end
    end
  end

  def mark_all_read
    if filtered_query.valid?
      filtered_query.results.update_all(read_ian: true, updated_at: Time.zone.now)
    else
      flash[:error] = filtered_query.errors.full_messages.join(", ")
    end

    redirect_back fallback_location: notifications_path
  end

  def date_alerts
    render_notifications_layout
  end

  def share_upsale
    render_notifications_layout
  end

  private

  def split_view_base_route = notifications_path(request.query_parameters)

  def default_breadcrumb; end

  def render_notifications_layout
    # Frontend will handle rendering
    # but we will need to render with notification specific layout
    render layout: "notifications"
  end

  def filtered_query
    query = Queries::Notifications::NotificationQuery.new(user: current_user)
    query.where(:read_ian, "=", "f")

    case params[:filter]
    when "project"
      id = params[:name].to_i
      query.where(:project_id, "=", [id])
    when "reason"
      query.where(:reason, "=", [params[:name]])
    end

    @filtered_query = query
  end
end
