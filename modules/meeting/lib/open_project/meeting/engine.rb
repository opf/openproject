#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'open_project/plugins'

module OpenProject::Meeting
  class Engine < ::Rails::Engine
    engine_name :openproject_meeting

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-meeting',
             author_url: 'https://www.openproject.org',
             bundled: true do
      project_module :meetings do
        permission :view_meetings,
                   { meetings: %i[index show],
                     meeting_agendas: %i[history show diff],
                     meeting_minutes: %i[history show diff] },
                   permissible_on: :project
        permission :create_meetings,
                   { meetings: %i[new create copy] },
                   permissible_on: :project,
                   require: :member,
                   contract_actions: { meetings: %i[create] }
        permission :edit_meetings,
                   { meetings: %i[edit update update_title update_details update_participants] },
                   permissible_on: :project,
                   require: :member
        permission :delete_meetings,
                   { meetings: [:destroy] },
                   permissible_on: :project,
                   require: :member
        permission :meetings_send_invite,
                   { meetings: [:icalendar] },
                   permissible_on: :project,
                   require: :member
        permission :create_meeting_agendas,
                   {
                     meeting_agendas: %i[update preview],
                     meeting_agenda_items: %i[new cancel_new create edit cancel_edit update destroy drop move]
                   },
                   permissible_on: :project,
                   require: :member
        permission :close_meeting_agendas,
                   {
                     meetings: %i[change_state],
                     meeting_agendas: %i[close open]
                   },
                   permissible_on: :project,
                   require: :member
        permission :send_meeting_agendas_notification,
                   { meeting_agendas: [:notify] },
                   permissible_on: :project,
                   require: :member
        permission :send_meeting_agendas_icalendar,
                   { meeting_agendas: [:icalendar] },
                   permissible_on: :project,
                   require: :member
        permission :create_meeting_minutes,
                   { meeting_minutes: %i[update preview] },
                   permissible_on: :project,
                   require: :member
        permission :send_meeting_minutes_notification,
                   { meeting_minutes: [:notify] },
                   permissible_on: :project,
                   require: :member
      end

      Redmine::Search.map do |search|
        search.register :meetings
      end

      menu :project_menu,
           :meetings, { controller: '/meetings', action: 'index' },
           caption: :project_module_meetings,
           after: :wiki,
           before: :members,
           icon: 'meetings'

      menu :project_menu,
           :meetings_query_select, { controller: '/meetings', action: 'index' },
           parent: :meetings,
           partial: 'meetings/menu_query_select'

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
        User.current.allowed_to_globally?(:view_meetings)
      end

      menu :top_menu,
           :meetings, { controller: '/meetings', action: 'index', project_id: nil },
           context: :modules,
           caption: :label_meeting_plural,
           last: true,
           icon: 'meetings',
           if: should_render_global_menu_item

      menu :global_menu,
           :meetings, { controller: '/meetings', action: 'index', project_id: nil },
           caption: :label_meeting_plural,
           last: true,
           icon: 'meetings',
           if: should_render_global_menu_item

      menu :global_menu,
           :meetings_query_select, { controller: '/meetings', action: 'index', project_id: nil },
           parent: :meetings,
           partial: 'meetings/menu_query_select',
           if: should_render_global_menu_item

      ActiveSupport::Inflector.inflections do |inflect|
        inflect.uncountable 'meeting_minutes'
      end
    end

    activity_provider :meetings, class_name: 'Activities::MeetingActivityProvider', default: false

    patches [:Project]
    patch_with_namespace :BasicData, :SettingSeeder

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::Meetings::MeetingContentsAPI
    end

    config.to_prepare do
      OpenProject::ProjectLatestActivity.register on: 'Meeting'

      PermittedParams.permit(:search, :meetings)
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

    add_api_path :attachments_by_meeting_content do |id|
      "#{meeting_content(id)}/attachments"
    end

    add_api_path :attachments_by_meeting_agenda do |id|
      attachments_by_meeting_content id
    end

    add_api_path :attachments_by_meeting_minutes do |id|
      attachments_by_meeting_content id
    end
  end
end
