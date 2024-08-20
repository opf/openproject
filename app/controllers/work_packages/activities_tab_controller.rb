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
    call = create_notification_service_call

    if call.success? && call.result
      if call.result.initial?
        # we need to update the whole item component for an initial journal entry
        # and not just the show part as happens in the time based update
        # as this part is not rendered for initial journal
        update_item_component(call.result, state: :show, filter: params[:filter]&.to_sym || :all)
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
      update_item_component(call.result, state: :show, filter: params[:filter]&.to_sym || :all)
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

  def create_notification_service_call
    ### taken from ActivitiesByWorkPackageAPI
    AddWorkPackageNoteService
      .new(user: User.current,
           work_package: @work_package)
      .call(journal_params[:notes],
            send_notifications: !(params.has_key?(:notify) && params[:notify] == "false"))
    ###
  end

  def update_item_component(journal, state: :show, filter: :all)
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal:,
        state:,
        filter:
      )
    )
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
        # we need to update the whole component as the show part is not rendered for journals which originally have no notes
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
          journal:,
          filter:
        )
      )
      # TODO: is it possible to loose an edit state this way?
    end

    journals.where("created_at > ?", last_update_timestamp).find_each do |journal|
      append_or_prepend_latest_journal_via_turbo_stream(journal, filter)
    end

    if journals.any?
      remove_potential_empty_state
    end
  end

  def append_or_prepend_latest_journal_via_turbo_stream(journal, filter)
    target_component = WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
      work_package: @work_package,
      filter:
    )

    component = WorkPackages::ActivitiesTab::Journals::ItemComponent.new(journal:, filter:)

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

  def remove_potential_empty_state
    # remove the empty state if it is present
    remove_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::EmptyComponent.new
    )
  end
end
