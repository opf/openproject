#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module OpenProject::GitlabIntegration
  class HookHandler
    # List of the github events we can handle.
    KNOWN_EVENTS = %w[push_hook issue_hook note_hook merge_request_hook].freeze

    # A github webhook happened.
    # We need to check validity of the data and send a Notification
    # which we process in our NotificationHandler.
    def process(hook, request, params, user)
      event_type = request.env['HTTP_X_GITLAB_EVENT']
      event_type.gsub!(' ','_')
      event_type = event_type.to_s.downcase
      #event_delivery = request.env['HTTP_X_GITHUB_DELIVERY']

      #Rails.logger.debug "Received github webhook #{event_type} (#{event_delivery})"
      Rails.logger.level = 0
      Rails.logger.debug "Received gitlab webhook #{event_type}"

      #return 404 unless KNOWN_EVENTS.include?(event_type) && event_delivery
      #return 200
      return 404 unless KNOWN_EVENTS.include?(event_type)
      return 403 unless user.present?

      payload = params[:payload]
                .permit!
                .to_h
                .merge('open_project_user_id' => user.id,
                       'gitlab_event' => event_type)#,
                       #'github_delivery' => event_delivery)

      OpenProject::Notifications.send(event_name(event_type), payload)

      return 200
    end

    private def event_name(gitlab_event_name)
      "gitlab.#{gitlab_event_name}"
    end
  end
end
