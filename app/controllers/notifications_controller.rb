#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
  layout 'no_menu'
  before_action :find_notification, only: %i[destroy]

  def index
    @notifications = DumbNotification
      .where(recipient: current_user)
  end

  def new
    @notification = DumbNotification.new
  end

  def create
    @notification = DumbNotification.new notification_params
    @notification.save

    respond_to do |format|
      format.html { redirect_to action: :index, notice: "Notification was successfully create." }
      format.turbo_stream
    end
  end

  def destroy
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to action: :index, notice: "Notification was successfully destroyed." }
      format.turbo_stream
    end
  end

  private

  def find_notification
    @notification = DumbNotification.find(params[:id])
    raise "Du Schlawiner!" if @notification.recipient != current_user
  end

  def notification_params
    params
      .require(:notification)
      .permit(:message)
      .merge(
        author: User.active.order(Arel.sql('RANDOM()')).first,
        recipient: current_user
      )
  end
end
