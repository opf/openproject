#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
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
        permission :view_meetings, meetings: %i[index show], meeting_agendas: %i[history show diff],
                                   meeting_minutes: %i[history show diff]
        permission :create_meetings, { meetings: %i[new create copy] }, require: :member
        permission :edit_meetings, { meetings: %i[edit update] }, require: :member
        permission :delete_meetings, { meetings: [:destroy] }, require: :member
        permission :meetings_send_invite, { meetings: [:icalendar] }, require: :member
        permission :create_meeting_agendas, { meeting_agendas: %i[update preview] }, require: :member
        permission :close_meeting_agendas, { meeting_agendas: %i[close open] }, require: :member
        permission :send_meeting_agendas_notification, { meeting_agendas: [:notify] }, require: :member
        permission :send_meeting_agendas_icalendar, { meeting_agendas: [:icalendar] }, require: :member
        permission :create_meeting_minutes, { meeting_minutes: %i[update preview] }, require: :member
        permission :send_meeting_minutes_notification, { meeting_minutes: [:notify] }, require: :member
      end

      Redmine::Search.map do |search|
        search.register :meetings
      end

      menu :project_menu,
           :meetings, { controller: '/meetings', action: 'index' },
           caption: :project_module_meetings,
           param: :project_id,
           after: :wiki,
           before: :members,
           icon: 'icon2 icon-meetings'

      ActiveSupport::Inflector.inflections do |inflect|
        inflect.uncountable 'meeting_minutes'
      end
    end

    activity_provider :meetings, class_name: 'Activities::MeetingActivityProvider', default: false

    patches [:Project]
    patch_with_namespace :BasicData, :RoleSeeder
    patch_with_namespace :BasicData, :SettingSeeder

    patch_with_namespace :OpenProject, :TextFormatting, :Formats, :Markdown, :TextileConverter

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::Meetings::MeetingContentsAPI
    end

    initializer 'meeting.register_latest_project_activity' do
      Project.register_latest_project_activity on: 'Meeting',
                                               attribute: :updated_at
    end

    config.to_prepare do
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
