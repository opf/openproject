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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackageWikisTabController < ApplicationController
  include OpTurbo::ComponentStream

  load_and_authorize_with_permission_in_project :view_work_packages

  before_action :set_work_package

  def index
    tab_component = Wikis::WorkPackageWikisTabComponent.new(@work_package)
    replace_via_turbo_stream(component: tab_component)

    respond_to_with_turbo_streams do |format|
      format.html do
        render(tab_component, layout: false)
      end
    end
  end

  private

  def set_work_package
    @work_package = @project.work_packages.visible.find(params[:work_package_id])
  end
end
