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

require "open_project/plugins"
require_relative "patches/api/work_package_representer"

module OpenProject::Meeting
  class Engine < ::Rails::Engine
    engine_name :openproject_meeting

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-meeting",
             author_url: "https://www.openproject.org",
             bundled: true do
      project_module :meetings do
        permission :view_meetings,
                   {
                     meetings: %i[index show check_for_updates download_ics
                                  presentation generate_pdf_dialog history project_items],
                     "meetings/filters": %i[show],
                     "meetings/menus": %i[show],
                     work_package_meetings_tab: %i[index count],
                     recurring_meetings: %i[index show new create download_ics]
                   },
                   permissible_on: :project,
                   contract_actions: { meetings: %i[read] }
        permission :create_meetings,
                   {
                     meetings: %i[new create copy new_dialog fetch_timezone fetch_templates],
                     recurring_meetings: %i[new create copy init template_completed],
                     "recurring_meetings/schedule": %i[update_text],
                     "meetings/menus": %i[show],
                     meeting_templates: %i[index new create new_dialog]
                   },
                   dependencies: :view_meetings,
                   permissible_on: :project,
                   require: :member,
                   contract_actions: { meetings: %i[create] }
        permission :edit_meetings,
                   {
                     meetings: %i[edit cancel_edit update update_title change_state change_sharing toggle_notifications_dialog
                                  details_dialog update_details toggle_notifications exit_draft_mode_dialog exit_draft_mode],
                     recurring_meetings: %i[edit cancel_edit update update_title details_dialog update_details
                                            notify end_series end_series_dialog],
                     work_package_meetings_tab: %i[add_work_package_to_meeting_dialog add_work_package_to_meeting refresh_form],
                     meeting_participants: %i[create destroy mark_all_attended toggle_attendance manage_participants_dialog]
                   },
                   permissible_on: :project,
                   dependencies: :view_meetings,
                   require: :member,
                   contract_actions: { meetings: %i[update] }
        permission :delete_meetings,
                   {
                     meetings: %i[delete_dialog destroy],
                     recurring_meetings: %i[delete_dialog destroy delete_scheduled_dialog destroy_scheduled]
                   },
                   permissible_on: :project,
                   dependencies: :view_meetings,
                   require: :member,
                   contract_actions: { meetings: %i[destroy] }
        permission :send_meeting_invites_and_outcomes,
                   { meetings: %i[notify icalendar] },
                   permissible_on: :project,
                   dependencies: :view_meetings,
                   require: :member
        permission :manage_agendas,
                   {
                     meeting_agenda_items: %i[new cancel_new create edit cancel_edit update destroy drop move
                                              move_to_next_meeting move_to_next_meeting_dialog
                                              duplicate_in_next_meeting duplicate_in_next_meeting_dialog
                                              move_to_section move_to_section_dialog],
                     meeting_sections: %i[new cancel_new create edit cancel_edit update destroy drop move
                                          clear_backlog clear_backlog_dialog]
                   },
                   permissible_on: :project, # TODO: Change this to :meeting when MeetingRoles are available
                   dependencies: :view_meetings,
                   require: :member,
                   contract_actions: { meeting_agenda_items: %i[create update destroy] }
        permission :manage_outcomes,
                   {
                     meeting_outcomes: %i[new cancel_new create edit cancel_edit update destroy]
                   },
                   permissible_on: :project,
                   dependencies: :view_meetings,
                   require: :member,
                   contract_actions: { meeting_outcomes: %i[create update destroy] }
      end

      Redmine::Search.map do |search|
        search.register :meetings
      end

      menu :project_menu,
           :meetings, { controller: "/meetings", action: "index" },
           caption: :project_module_meetings,
           after: :boards,
           icon: "comment-discussion"

      menu :project_menu,
           :meetings_query_select, { controller: "/meetings", action: "index" },
           parent: :meetings,
           partial: "meetings/menus/menu"

      menu :work_package_split_view,
           :meetings,
           { tab: :meetings },
           skip_permissions_check: true,
           after: :relations,
           if: ->(_project) {
             User.current.allowed_in_any_project?(:view_meetings)
           },
           badge: ->(work_package:, **) {
             Meeting.visible.where(id: work_package.meetings.select(:id)).count
           },
           caption: :label_meeting_plural

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
          User.current.allowed_in_any_project?(:view_meetings)
      end

      menu :top_menu,
           :meetings, { controller: "/meetings", action: "index", project_id: nil },
           context: :modules,
           caption: :label_meeting_plural,
           after: :boards,
           icon: "comment-discussion",
           if: should_render_global_menu_item

      menu :global_menu,
           :meetings, { controller: "/meetings", action: "index", project_id: nil },
           caption: :label_meeting_plural,
           after: :boards,
           icon: "comment-discussion",
           if: should_render_global_menu_item

      menu :global_menu,
           :meetings_query_select, { controller: "/meetings", action: "index", project_id: nil },
           parent: :meetings,
           partial: "meetings/menus/menu",
           if: should_render_global_menu_item

      ActiveSupport::Inflector.inflections do |inflect|
        inflect.uncountable "meeting_minutes"
      end
    end

    activity_provider :meetings, class_name: "Activities::MeetingActivityProvider", default: false

    patches [:Project]
    patch_with_namespace :BasicData, :SettingSeeder

    replace_principal_references "Meeting" => %i[author_id],
                                 "MeetingAgendaItem" => %i[author_id presenter_id],
                                 "MeetingOutcome" => :author_id,
                                 "MeetingParticipant" => :user_id,
                                 "RecurringMeeting" => :author_id

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::Meeting::Patches::API::WorkPackageRepresenter.extension)

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Meetings::MeetingsAPI
      mount ::API::V3::RecurringMeetings::RecurringMeetingsAPI
    end

    config.to_prepare do
      OpenProject::ProjectLatestActivity.register on: "Meeting"

      PermittedParams.permit(:search, :meetings)

      ::Exports::Register.register do
        single(::Meeting, Meetings::Exporter)
      end

      Journals::CreateService::Association.register(:AgendaItemable)
      Journals::CreateService::Association.register(:Participatable)
    end

    add_api_path :meetings do
      "#{root}/meetings"
    end

    add_api_path :meeting do |id|
      "#{root}/meetings/#{id}"
    end

    add_api_path :meeting_content do |id|
      "#{root}/meeting_contents/#{id}"
    end

    add_api_path :meeting_agenda do |id|
      meeting_content(id)
    end

    add_api_path :meeting_minutes do |id|
      meeting_content(id)
    end

    add_api_path :attachments_by_meeting do |id|
      "#{meeting(id)}/attachments"
    end

    add_api_path :meeting_schema do
      "#{root}/meetings/schema"
    end

    add_api_path :create_meeting_form do
      "#{root}/meetings/form"
    end

    add_api_path :meeting_form do |id|
      "#{root}/meetings/#{id}/form"
    end

    add_api_path :meeting_agenda_items do |meeting_id: nil|
      if meeting_id
        "#{meeting(meeting_id)}/agenda_items"
      else
        "#{root}/meeting_agenda_items"
      end
    end

    add_api_path :meeting_agenda_item do |id, meeting_id: nil|
      if meeting_id
        "#{meeting(meeting_id)}/agenda_items/#{id}"
      else
        "#{root}/meeting_agenda_items/#{id}"
      end
    end

    add_api_path :meeting_agenda_item_outcomes do |agenda_item_id, meeting_id: nil|
      "#{meeting_agenda_item(agenda_item_id, meeting_id:)}/outcomes"
    end

    add_api_path :meeting_outcomes do
      "#{root}/meeting_outcomes"
    end

    add_api_path :meeting_outcome do |id|
      "#{root}/meeting_outcomes/#{id}"
    end

    add_api_path :meeting_agenda_item_outcome do |id, agenda_item_id:, meeting_id: nil|
      "#{meeting_agenda_item_outcomes(agenda_item_id, meeting_id:)}/#{id}"
    end

    add_api_path :meeting_sections do |meeting_id: nil|
      if meeting_id
        "#{meeting(meeting_id)}/sections"
      else
        "#{root}/meeting_sections"
      end
    end

    add_api_path :meeting_section do |id, meeting_id: nil|
      if meeting_id
        "#{meeting(meeting_id)}/sections/#{id}"
      else
        "#{root}/meeting_sections/#{id}"
      end
    end

    add_api_path :recurring_meetings do
      "#{root}/recurring_meetings"
    end

    add_api_path :recurring_meeting do |id|
      "#{root}/recurring_meetings/#{id}"
    end

    add_api_path :recurring_meeting_occurrences_upcoming do |id|
      "#{recurring_meeting(id)}/occurrences/upcoming"
    end

    add_api_path :recurring_meeting_occurrences_past do |id|
      "#{recurring_meeting(id)}/occurrences/past"
    end

    add_api_path :recurring_meeting_occurrences_cancelled do |id|
      "#{recurring_meeting(id)}/occurrences/cancelled"
    end

    add_api_path :recurring_meeting_occurrences_open do |id|
      "#{recurring_meeting(id)}/occurrences/open"
    end

    add_api_path :recurring_meeting_occurrence do |id, start_time|
      "#{recurring_meeting(id)}/occurrences/#{start_time}"
    end
  end
end
