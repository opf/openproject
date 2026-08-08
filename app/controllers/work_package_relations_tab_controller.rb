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

class WorkPackageRelationsTabController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :set_work_package
  before_action :authorize_global

  def index
    component = WorkPackageRelationsTab::IndexComponent.new(work_package: @work_package)

    respond_to do |format|
      format.html do
        render(component, layout: false)
      end
      format.turbo_stream do
        replace_via_turbo_stream(component:, method: "morph")
        render turbo_stream: resolve_turbo_streams
      end
    end
  end

  private

  def set_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
    @project = @work_package.project # required for authorization via before_action
  end
end
