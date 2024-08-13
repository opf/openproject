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

require "rack/utils"

class WorkPackages::SplitViewController < ApplicationController
  # Authorization is checked in the find_work_package action
  no_authorization_required! :update_counter
  before_action :find_work_package, only: %i[update_counter]
  before_action :find_counter_menu, only: %i[update_counter]

  def update_counter
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("wp-details-tab-#{@counter_menu.name}-counter") do
            count = @counter_menu.badge(work_package: @work_package).to_i
            Primer::Beta::Counter
              .new(count:,
                   hide_if_zero: true,
                   id: "wp-details-tab-#{@counter_menu.name}-counter",
                   test_selector: "wp-details-tab-component--tab-counter")
              .render_in(view_context)
          end
        ]
      end
    end
  end

  private

  def find_work_package
    @work_package = WorkPackage.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404 message: I18n.t(:error_work_package_id_not_found)
  end

  def find_counter_menu
    @counter_menu = Redmine::MenuManager
      .items(:work_package_split_view, nil)
      .root
      .children
      .detect { |node| node.name.to_s == params[:counter] }

    render_400 if @counter_menu.nil?
  end
end
