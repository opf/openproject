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
  before_action :set_filter
  before_action :authorize

  def index
    render(
      WorkPackages::ActivitiesTab::IndexComponent.new(
        work_package: @work_package,
        filter: @filter
      ),
      layout: false
    )
  end

  def update_streams
    if params[:last_update_timestamp].present?
      generate_time_based_update_streams(params[:last_update_timestamp])
    else
      @turbo_status = :bad_request
    end

    respond_with_turbo_streams
  end

  def update_filter
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::FilterAndSortingComponent.new(
        work_package: @work_package,
        filter: @filter
      )
    )
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
        work_package: @work_package,
        filter: @filter
      )
    )

    respond_with_turbo_streams
  end

  def update_sorting
    if params[:sorting].present?
      call = Users::UpdateService.new(user: User.current, model: User.current).call(
        pref: { comments_sorting: params[:sorting] }
      )

      if call.success?
        # update the whole tab to reflect the new sorting in all components
        # we need to call replace in order to properly re-init the index stimulus component
        replace_whole_tab
      else
        @turbo_status = :bad_request
      end
    else
      @turbo_status = :bad_request
    end

    respond_with_turbo_streams
  end

  def edit
    if allowed_to_edit?(@journal)
      update_item_component(journal: @journal, state: :edit)
    else
      @turbo_status = :forbidden
    end

    respond_with_turbo_streams
  end

  def cancel_edit
    if allowed_to_edit?(@journal)
      update_item_component(journal: @journal, state: :show)
    else
      @turbo_status = :forbidden
    end

    respond_with_turbo_streams
  end

  def create
    call = create_journal_service_call

    if call.success? && call.result
      handle_successful_create_call(call)
    else
      handle_failed_create_call(call) # errors should be rendered in the form
      @turbo_status = :bad_request
    end

    respond_with_turbo_streams
  end

  def update
    call = Journals::UpdateService.new(model: @journal, user: User.current).call(
      notes: journal_params[:notes]
    )

    if call.success? && call.result
      update_item_component(journal: call.result, state: :show)
    else
      handle_failed_update_call(call)
    end

    respond_with_turbo_streams
  end

  private

  def respond_with_error(error_message)
    respond_to do |format|
      # turbo_frame requests (tab is initially rendered and an error occured) are handled below
      format.html do
        render(
          WorkPackages::ActivitiesTab::ErrorFrameComponent.new(
            error_message:
          ),
          layout: false,
          status: :not_found
        )
      end
      # turbo_stream requests (tab is already rendered and an error occured in subsequent requests) are handled below
      format.turbo_stream do
        @turbo_status = :not_found
        render_error_banner_via_turbo_stream(error_message)
      end
    end
  end

  def render_error_banner_via_turbo_stream(error_message)
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::ErrorStreamComponent.new(
        error_message:
      )
    )
  end

  def find_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
  rescue ActiveRecord::RecordNotFound
    respond_with_error(I18n.t("label_not_found"))
  end

  def find_project
    @project = @work_package.project
  rescue ActiveRecord::RecordNotFound
    respond_with_error(I18n.t("label_not_found"))
  end

  def find_journal
    @journal = Journal.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_with_error(I18n.t("label_not_found"))
  end

  def set_filter
    @filter = params[:filter]&.to_sym || :all
  end

  def journal_sorting
    User.current.preference&.comments_sorting || "desc"
  end

  def journal_params
    params.require(:journal).permit(:notes)
  end

  def handle_successful_create_call(call)
    if @filter == :only_changes
      handle_only_changes_filter_on_create
    else
      handle_other_filters_on_create(call)
    end
  end

  def handle_only_changes_filter_on_create
    @filter = :all # reset filter
    # we need to update the whole tab in order to reset the filter
    # as the added journal would not be shown otherwise
    replace_whole_tab
  end

  def handle_other_filters_on_create(call)
    if call.result.initial?
      update_index_component # update the whole index component to reset empty state
    else
      generate_time_based_update_streams(params[:last_update_timestamp])
    end
  end

  def handle_failed_create_call(call)
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::NewComponent.new(
        work_package: @work_package,
        journal: call.result,
        form_hidden_initially: false
      )
    )
  end

  def handle_failed_update_call(call)
    @turbo_status = if call.errors&.first&.type == :error_unauthorized
                      :forbidden
                    else
                      :bad_request
                    end
  end

  def replace_whole_tab
    replace_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::IndexComponent.new(
        work_package: @work_package,
        filter: @filter
      )
    )
  end

  def update_index_component
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
        work_package: @work_package,
        filter: @filter
      )
    )
  end

  def create_journal_service_call
    ### taken from ActivitiesByWorkPackageAPI
    AddWorkPackageNoteService
      .new(user: User.current,
           work_package: @work_package)
      .call(journal_params[:notes],
            send_notifications: !(params.has_key?(:notify) && params[:notify] == "false"))
    ###
  end

  def update_item_component(journal:, filter: @filter, state: :show)
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal:,
        state:,
        filter:
      )
    )
  end

  def generate_time_based_update_streams(last_update_timestamp)
    journals = @work_package.journals

    if @filter == :only_comments
      journals = journals.where.not(notes: "")
    end

    rerender_updated_journals(journals, last_update_timestamp)

    rerender_journals_with_updated_notification(journals, last_update_timestamp)

    append_or_prepend_journals(journals, last_update_timestamp)

    if journals.any?
      remove_potential_empty_state
      update_activity_counter
    end
  end

  def rerender_updated_journals(journals, last_update_timestamp)
    journals.where("updated_at > ?", last_update_timestamp).find_each do |journal|
      update_item_component(journal:)
    end
  end

  def rerender_journals_with_updated_notification(journals, last_update_timestamp)
    # Case: the user marked the journal as read somewhere else and expects the bubble to disappear
    journals
      .joins(:notifications)
      .where("notifications.updated_at > ?", last_update_timestamp)
      .find_each do |journal|
      update_item_component(journal:)
    end
  end

  def append_or_prepend_journals(journals, last_update_timestamp)
    journals.where("created_at > ?", last_update_timestamp).find_each do |journal|
      append_or_prepend_latest_journal_via_turbo_stream(journal)
    end
  end

  def append_or_prepend_latest_journal_via_turbo_stream(journal)
    target_component = WorkPackages::ActivitiesTab::Journals::IndexComponent.new(
      work_package: @work_package,
      filter: @filter
    )

    component = WorkPackages::ActivitiesTab::Journals::ItemComponent.new(journal:, filter: @filter)

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

  def update_activity_counter
    # update the activity counter in the primerized tabs
    # not targeting the legacy tab!
    replace_via_turbo_stream(
      component: WorkPackages::Details::UpdateCounterComponent.new(work_package: @work_package, menu_name: "activity")
    )
  end

  def allowed_to_edit?(journal)
    journal.editable_by?(User.current)
  end
end
