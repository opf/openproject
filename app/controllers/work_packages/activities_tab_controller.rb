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
  before_action :find_journal, only: %i[edit cancel_edit update]
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
    # TODO: prototypical implementation
    @work_package.journals.where("updated_at > ?", params[:last_update_timestamp]).find_each do |journal|
      update_via_turbo_stream(
        # only use the show component in order not to loose an edit state
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent::Show.new(
          journal:
        )
      )
    end

    @work_package.journals.where("created_at > ?", params[:last_update_timestamp]).find_each do |journal|
      append_or_prepend_latest_journal_via_turbo_stream(journal)
    end

    respond_with_turbo_streams
  end

  def edit
    # check if allowed to edit at all
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal: @journal,
        state: :edit
      )
    )

    respond_with_turbo_streams
  end

  def cancel_edit
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal: @journal,
        state: :show
      )
    )

    respond_with_turbo_streams
  end

  def create
    latest_journal_version = @work_package.journals.last.try(:version) || 0

    call = Journals::CreateService.new(@work_package, User.current).call(
      notes: journal_params[:notes]
    )

    if call.success? && call.result
      after_create_turbo_stream(call, latest_journal_version)
    end

    clear_form_via_turbo_stream

    respond_with_turbo_streams
  end

  def update
    call = Journals::UpdateService.new(model: @journal, user: User.current).call(
      notes: journal_params[:notes]
    )

    if call.success? && call.result
      update_via_turbo_stream(
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
          journal: call.result,
          state: :show
        )
      )
    end
    # TODO: handle errors

    respond_with_turbo_streams
  end

  private

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  end

  def find_project
    @project = @work_package.project
  end

  def find_journal
    @journal = Journal.find(params[:id])
  end

  def journal_sorting
    User.current.preference&.comments_sorting || "desc"
  end

  def journal_params
    params.require(:journal).permit(:notes)
  end

  def after_create_turbo_stream(call, latest_journal_version)
    # journals might get merged in some cases,
    # thus we need to check if the journal is already present and update it rather then ap/prepending it
    if latest_journal_version < call.result.version
      append_or_prepend_latest_journal_via_turbo_stream(call.result)
    else
      update_journal_via_turbo_stream(call.result)
    end
  end

  def append_or_prepend_latest_journal_via_turbo_stream(journal)
    stream_config = {
      target_component: WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
        work_package: @work_package
      ),
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal:
      )
    }

    # Append or prepend the new journal depending on the sorting
    if journal_sorting == "asc"
      append_via_turbo_stream(**stream_config)
    else
      prepend_via_turbo_stream(**stream_config)
    end
  end

  def update_journal_via_turbo_stream(journal)
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(journal:)
    )
  end

  def clear_form_via_turbo_stream
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::NewComponent.new(
        work_package: @work_package
      )
    )
  end
end
