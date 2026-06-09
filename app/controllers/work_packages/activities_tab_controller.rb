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
  include FlashMessagesOutputSafetyHelper
  include WorkPackages::ActivitiesTab::JournalSortingInquirable
  include WorkPackages::ActivitiesTab::StimulusControllers

  Filters = WorkPackages::ActivitiesTab::Filters

  before_action :find_work_package
  before_action :find_journal, only: %i[emoji_actions item_actions edit cancel_edit update toggle_reaction]
  before_action :set_filter
  before_action :authorize
  before_action :initialize_pagination, only: %i[index page_streams]

  def index
    render(
      WorkPackages::ActivitiesTab::LazyIndexComponent.new(
        work_package: @work_package,
        journals: @paginated_journals,
        paginator: @paginator,
        filter: @filter,
        last_server_timestamp: get_current_server_timestamp,
        resolved_anchor: @resolved_anchor
      ),
      layout: false
    )
  end

  def page_streams
    replace_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::PageComponent.new(
        journals: @paginated_journals,
        emoji_reactions: wp_journals_emoji_reactions,
        page: @paginator.page,
        filter: @filter
      )
    )

    respond_with_turbo_streams
  end

  def update_streams
    set_last_server_timestamp_to_headers

    perform_update_streams_from_last_update_timestamp

    respond_with_turbo_streams
  end

  def update_filter
    # update the whole tab to reflect the new filtering in all components
    # we need to call replace in order to properly re-init the index stimulus component
    replace_whole_tab

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

  def emoji_actions
    render WorkPackages::ActivitiesTab::Journals::ItemComponent::AddReactions
            .new(journal: @journal, grouped_emoji_reactions: grouped_emoji_reactions_for_journal),
           layout: false
  end

  def item_actions
    render WorkPackages::ActivitiesTab::Journals::ItemComponent::Actions.new(@journal),
           layout: false
  end

  def edit
    if allowed_to_edit?(@journal)
      update_item_edit_component(journal: @journal)
    else
      @turbo_status = :forbidden
    end

    respond_with_turbo_streams
  end

  def cancel_edit
    if allowed_to_edit?(@journal)
      update_item_show_component(journal: @journal, grouped_emoji_reactions: grouped_emoji_reactions_for_journal)
    else
      @turbo_status = :forbidden
    end

    respond_with_turbo_streams
  end

  def create
    begin
      call = create_journal_service_call

      if call.success? && call.result
        set_last_server_timestamp_to_headers
        handle_successful_create_call(call)
      else
        handle_failed_create_or_update_call(call)
      end
    rescue StandardError => e
      handle_internal_server_error(e)
    end

    respond_with_turbo_streams
  end

  def update
    begin
      call = update_journal_service_call

      if call.success? && call.result
        update_item_show_component(journal: call.result, grouped_emoji_reactions: grouped_emoji_reactions_for_journal)
      else
        handle_failed_create_or_update_call(call)
      end
    rescue StandardError => e
      handle_internal_server_error(e)
    end

    respond_with_turbo_streams
  end

  def sanitize_internal_mentions
    render plain: sanitized_journal_notes
  rescue StandardError => e
    handle_internal_server_error(e)
    respond_with_turbo_streams
  end

  def toggle_reaction
    emoji_reaction_service = EmojiReactions::ToggleEmojiReactionService
      .call(user: User.current,
            reactable: @journal,
            reaction: params[:reaction])

    emoji_reaction_service.on_success do
      update_via_turbo_stream(
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent::Show.new(
          journal: @journal,
          filter: @filter,
          grouped_emoji_reactions: grouped_emoji_reactions_for_journal
        )
      )
    end

    emoji_reaction_service.on_failure do
      render_error_flash_message_via_turbo_stream(
        message: join_flash_messages(emoji_reaction_service.errors.full_messages)
      )
    end

    respond_with_turbo_streams
  end

  private

  def find_work_package
    @work_package = WorkPackage.visible.find(params[:work_package_id])
    @project = @work_package.project
  rescue ActiveRecord::RecordNotFound
    respond_with_error(I18n.t("label_not_found"))
  end

  def initialize_pagination
    paginator = WorkPackages::ActivitiesTab::Paginator.new(@work_package, params.merge(filter: @filter, limit: 20))
    @paginator, @paginated_journals = paginator.call
    @resolved_anchor = paginator.resolved_anchor
  end

  def respond_with_error(error_message)
    @turbo_status = :not_found
    render_error_flash_message_via_turbo_stream(message: error_message)

    respond_to_with_turbo_streams do |format|
      format.html do
        render(
          WorkPackages::ActivitiesTab::ErrorFrameComponent.new(error_message: error_message),
          layout: false,
          status: :not_found
        )
      end
      # turbo_stream requests (tab is already rendered and an error occured in subsequent requests) are handled below
      format.turbo_stream do
        @turbo_status = :not_found
        render_error_flash_message_via_turbo_stream(message: error_message)
        render turbo_stream: turbo_streams, status: :not_found
      end
    end
  end

  def find_journal
    @journal = @work_package
      .journals
      .internal_visible
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_with_error(I18n.t("label_not_found"))
  end

  def set_filter
    @filter = Filters.cast(params[:filter] || params.dig(:journal, :filter))
  end

  def sanitized_journal_notes
    WorkPackages::ActivitiesTab::InternalCommentMentionsSanitizer.sanitize(@work_package, journal_params[:notes])
  end

  def journal_params
    params.expect(journal: %i[notes internal])
  end

  def handle_successful_create_call(call)
    if @filter == Filters::ONLY_CHANGES
      handle_only_changes_filter_on_create
    else
      handle_other_filters_on_create(call)
    end
  end

  def handle_only_changes_filter_on_create
    @filter = Filters::ALL # reset filter
    # we need to update the whole tab in order to reset the filter
    # as the added journal would not be shown otherwise
    replace_whole_tab
  end

  def handle_other_filters_on_create(call)
    if call.result.initial?
      update_index_component # update the whole index component to reset empty state
    else
      perform_update_streams_from_last_update_timestamp
    end
  end

  def perform_update_streams_from_last_update_timestamp
    last_update_timestamp = params[:last_update_timestamp] || params.dig(:journal, :last_update_timestamp)
    editing_journals = params[:editing_journals]&.split(",")&.map(&:to_i) || []

    if last_update_timestamp.present?
      last_updated_at = Time.zone.parse(last_update_timestamp)
      generate_time_based_update_streams(last_updated_at, editing_journals)
      generate_work_package_journals_emoji_reactions_update_streams
    else
      @turbo_status = :bad_request
    end
  end

  def handle_failed_create_or_update_call(call)
    @turbo_status = if call.errors&.first&.type == :error_unauthorized
                      :forbidden
                    else
                      :bad_request
                    end
    render_error_flash_message_via_turbo_stream(
      message: call.errors&.full_messages&.join(", ")
    )
  end

  def handle_internal_server_error(error)
    @turbo_status = :internal_server_error
    render_error_flash_message_via_turbo_stream(
      message: error.message
    )
  end

  def replace_whole_tab
    initialize_pagination # re-initialize pagination to pick up changes to sorting/filtering
    replace_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::LazyIndexComponent.new(
        work_package: @work_package,
        journals: @paginated_journals,
        paginator: @paginator,
        filter: @filter,
        last_server_timestamp: get_current_server_timestamp,
        resolved_anchor: @resolved_anchor
      )
    )
  end

  def update_index_component
    initialize_pagination # re-initialize pagination to pick up changes to sorting/filtering
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::LazyIndexComponent.new(
        work_package: @work_package,
        journals: @paginated_journals,
        paginator: @paginator,
        filter: @filter
      )
    )
  end

  def create_journal_service_call
    internal = to_boolean(journal_params[:internal], false)
    notes = internal ? sanitized_journal_notes : journal_params[:notes]

    AddWorkPackageNoteService
      .new(user: User.current,
           work_package: @work_package)
      .call(notes,
            send_notifications: to_boolean(params[:notify], true),
            internal:)
  end

  def to_boolean(value, default)
    ActiveRecord::Type::Boolean.new.cast(value.presence || default)
  end

  def update_journal_service_call
    notes = @journal.internal? ? sanitized_journal_notes : journal_params[:notes]
    Journals::UpdateService.new(model: @journal, user: User.current).call(notes:)
  end

  def generate_time_based_update_streams(last_update_timestamp, editing_journals)
    journals = @work_package
                 .journals
                 .internal_visible

    if @filter == Filters::ONLY_COMMENTS
      journals = journals.where.not(notes: "")
    end

    grouped_emoji_reactions = EmojiReactions::GroupedQueries.grouped_emoji_reactions_by_reactable(
      reactable_id: journals.pluck(:id), reactable_type: "Journal"
    )

    rerender_updated_journals(journals, last_update_timestamp, grouped_emoji_reactions, editing_journals)
    rerender_journals_with_updated_notification(journals, last_update_timestamp, grouped_emoji_reactions, editing_journals)
    insert_latest_journals_via_turbo_stream(journals, last_update_timestamp, grouped_emoji_reactions)

    if journals.present?
      remove_potential_empty_state
      update_activity_counter
    end
  end

  def generate_work_package_journals_emoji_reactions_update_streams
    @work_package.journals.each do |journal|
      update_via_turbo_stream(
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent::Reactions.new(
          journal:,
          grouped_emoji_reactions: wp_journals_emoji_reactions[journal.id] || {}
        )
      )
    end
  end

  def rerender_updated_journals(journals, last_update_timestamp, grouped_emoji_reactions, editing_journals)
    journals.where("updated_at > ?", last_update_timestamp).find_each do |journal|
      next if editing_journals.include?(journal.id)

      update_item_show_component(journal:, grouped_emoji_reactions: grouped_emoji_reactions.fetch(journal.id, {}))
    end
  end

  def rerender_journals_with_updated_notification(journals, last_update_timestamp, grouped_emoji_reactions, editing_journals)
    Notification
      .where(journal_id: journals.pluck(:id))
      .where(recipient_id: User.current.id)
      .where("notifications.updated_at > ?", last_update_timestamp)
      .find_each do |notification|
        next if editing_journals.include?(notification.journal_id)

        update_item_show_component(
          journal: journals.find(notification.journal_id),
          grouped_emoji_reactions: grouped_emoji_reactions.fetch(notification.journal_id, {})
        )
      end
  end

  def insert_latest_journals_via_turbo_stream(journals, last_update_timestamp, emoji_reactions)
    target_component = WorkPackages::ActivitiesTab::Journals::LazyIndexComponent.new(
      work_package: @work_package,
      journals: Journal.none, # we do not need to pass any journals here since we just want the component key
      paginator: nil,
      filter: @filter
    )

    journals.where("created_at > ?", last_update_timestamp).find_each do |journal|
      insert_via_turbo_stream(
        target_component:,
        component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
          journal:, filter: @filter, grouped_emoji_reactions: emoji_reactions.fetch(journal.id, {})
        ),
        action: journal_sorting.asc? ? :append : :prepend
      )
    end
  end

  def remove_potential_empty_state
    # remove the empty state if it is present
    remove_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::EmptyComponent.new
    )
  end

  def update_item_edit_component(journal:, grouped_emoji_reactions: {})
    update_item_component(journal:, state: :edit, grouped_emoji_reactions:)
  end

  def update_item_show_component(journal:, grouped_emoji_reactions:)
    update_item_component(journal:, state: :show, grouped_emoji_reactions:)
  end

  def update_item_component(journal:, grouped_emoji_reactions:, state:, filter: @filter)
    update_via_turbo_stream(
      component: WorkPackages::ActivitiesTab::Journals::ItemComponent.new(
        journal:,
        state:,
        filter:,
        grouped_emoji_reactions:
      )
    )
  end

  def update_activity_counter
    # update the activity counter in the primerized tabs
    # not targeting the legacy tab!
    replace_via_turbo_stream(
      component: WorkPackages::Details::UpdateCounterComponent.new(work_package: @work_package, menu_name: "activity")
    )
  end

  def wp_journals_emoji_reactions
    @wp_journals_emoji_reactions ||= EmojiReactions::GroupedQueries
      .grouped_work_package_journals_emoji_reactions_by_reactable(@work_package)
  end

  def grouped_emoji_reactions_for_journal
    EmojiReactions::GroupedQueries
      .grouped_emoji_reactions_by_reactable(reactable: @journal)[@journal.id]
  end

  def allowed_to_edit?(journal)
    journal.editable_by?(User.current)
  end

  def get_current_server_timestamp
    # single source of truth for the server timestamp format
    Time.current.iso8601(3)
  end

  def set_last_server_timestamp_to_headers
    # Add server timestamp to response in order to let the client be in sync with the server
    response.headers["X-Server-Timestamp"] = get_current_server_timestamp
  end
end
