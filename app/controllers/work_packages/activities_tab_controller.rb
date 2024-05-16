# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

class WorkPackages::ActivitiesTabController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :find_work_package
  before_action :find_project
  before_action :authorize

  def index
    render(
      WorkPackages::ActivitiesTab::IndexComponent.new(
        work_package: @work_package
      ),
      layout: false
    )
  end

  def journal_streams
    # TODO: only update specific journal components or append/prepend new journals based on latest client state
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::IndexComponent.new(
        work_package: @work_package
      )
    )

    respond_with_turbo_streams
  end

  def create
    call = Journals::CreateService.new(@work_package, User.current).call(
      notes: journal_params[:notes]
    )

    if call.success?
      stream_config = {
        target_component: WorkPackages::ActivitiesTab::IndexComponent.new(
          work_package: @work_package
        ),
        component: WorkPackages::ActivitiesTab::Journals::ShowComponent.new(
          journal: call.result
        )
      }

      # Append or prepend the new journal depending on the sorting
      if journal_sorting == "asc"
        append_via_turbo_stream(**stream_config)
      else
        prepend_via_turbo_stream(**stream_config)
      end

      # Clear the form
      update_via_turbo_stream(
        component: WorkPackages::ActivitiesTab::Journals::FormComponent.new(
          work_package: @work_package
        )
      )
    end

    respond_with_turbo_streams
  end

  private

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def find_project
    @project = @work_package.project
  end

  def journal_sorting
    User.current.preference&.comments_sorting || "desc"
  end

  def journal_params
    params.require(:journal).permit(:notes)
  end
end
