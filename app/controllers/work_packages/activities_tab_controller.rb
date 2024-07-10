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
        work_package: @work_package,
        filter: params[:filter]&.to_sym || :all
      ),
      layout: false
    )
  end

  def update_filter
    filter = params[:filter]&.to_sym || :all

    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::FilterAndSortingComponent.new(
        work_package: @work_package,
        filter:
      )
    )
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
        work_package: @work_package,
        filter:
      )
    )

    respond_with_turbo_streams
  end

  def update_streams
    generate_time_based_update_streams(params[:last_update_timestamp], params[:filter])

    respond_with_turbo_streams
  end

  def edit
    # check if allowed to edit at all
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal: @journal,
        state: :edit,
        filter: params[:filter]&.to_sym || :all
      )
    )

    respond_with_turbo_streams
  end

  def cancel_edit
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal: @journal,
        state: :show,
        filter: params[:filter]&.to_sym || :all
      )
    )

    respond_with_turbo_streams
  end

  def create
    ### taken from ActivitiesByWorkPackageAPI
    call = AddWorkPackageNoteService
      .new(user: User.current,
           work_package: @work_package)
      .call(journal_params[:notes],
            send_notifications: !(params.has_key?(:notify) && params[:notify] == "false"))
    ###

    if call.success? && call.result
      if call.result.initial?
        # we need to update the whole item component for an initial journal entry
        # and not just the show part as happens in the time based update
        # as this part is not rendered for initial journal
        update_via_turbo_stream(
          component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
            journal: call.result,
            state: :show,
            filter: params[:filter]&.to_sym || :all
          )
        )
      end
      generate_time_based_update_streams(params[:last_update_timestamp], params[:filter])
    end

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
          state: :show,
          filter: params[:filter]&.to_sym || :all
        )
      )
    end
    # TODO: handle errors

    respond_with_turbo_streams
  end

  def update_sorting
    filter = params[:filter]&.to_sym || :all

    call = Users::UpdateService.new(user: User.current, model: User.current).call(
      pref: { comments_sorting: params[:sorting] }
    )

    if call.success?
      # update the whole tab to reflect the new sorting in all components
      # we need to call replace in order to properly re-init the index stimulus component
      replace_via_turbo_stream(
        component: WorkPackages::ActivitiesTab::IndexComponent.new(
          work_package: @work_package,
          filter:
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

  def find_journal
    @journal = Journal.find(params[:id])
  end

  def journal_sorting
    User.current.preference&.comments_sorting || "desc"
  end

  def journal_params
    params.require(:journal).permit(:notes)
  end

  def generate_time_based_update_streams(last_update_timestamp, filter)
    filter = filter&.to_sym || :all
    # TODO: prototypical implementation
    journals = @work_package.journals

    if filter == :only_comments
      journals = journals.where.not(notes: "")
    end

    journals.where("updated_at > ?", last_update_timestamp).find_each do |journal|
      update_via_turbo_stream(
        # only use the show component in order not to loose an edit state
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent::Show.new(
          journal:,
          filter:
        )
      )
      update_via_turbo_stream(
        # only use the show component in order not to loose an edit state
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent::Details.new(
          journal:,
          filter:
        )
      )
    end

    latest_journal_visible_for_user = journals.where(created_at: ..last_update_timestamp).last

    journals.where("created_at > ?", last_update_timestamp).find_each do |journal|
      append_or_prepend_latest_journal_via_turbo_stream(journal, latest_journal_visible_for_user, filter)
    end
  end

  def append_or_prepend_latest_journal_via_turbo_stream(journal, latest_journal, filter)
    if latest_journal.created_at.to_date == journal.created_at.to_date
      target_component = WorkPackages::ActivitiesTab::Journals::DayComponent.new(
        work_package: @work_package,
        day_as_date: journal.created_at.to_date,
        journals: [journal], # we don't need to pass all actual journals of this day as we do not really render this component
        filter:
      )
      component = WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal:,
        filter:
      )
    else
      target_component = WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
        work_package: @work_package,
        filter:
      )
      component = WorkPackages::ActivitiesTab::Journals::DayComponent.new(
        work_package: @work_package,
        day_as_date: journal.created_at.to_date,
        journals: [journal],
        filter:
      )
    end
    stream_config = {
      target_component:,
      component:
    }

    # Append or prepend the new journal depending on the sorting
    if journal_sorting == "asc"
      append_via_turbo_stream(**stream_config)
    else
      prepend_via_turbo_stream(**stream_config)
    end
  end
end
