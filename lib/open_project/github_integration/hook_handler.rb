#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::GithubIntegration
  class HookHandler
    # List of the github events we can handle.
    KNOWN_EVENTS = %w{ ping pull_request issue_comment }

    # A github webhook happened.
    # We need to check validity of the data and send a Notification
    # which we process in our NotificationHandler.
    def process(hook, environment, params, user)
      event_type = environment['HTTP_X_GITHUB_EVENT']
      event_delivery = environment['HTTP_X_GITHUB_DELIVERY']

      Rails.logger.debug "Received github webhook #{event_type} (#{event_delivery})"

      return 404 unless KNOWN_EVENTS.include?(event_type) && event_delivery
      return 403 unless user.present?

      payload = Hash.new
      payload.merge! params.require('webhook')
      payload.merge! 'user_id' => user.id,
                     'github_event' => event_type,
                     'github_delivery' => event_delivery

      OpenProject::Notifications.send(event_name(event_type), payload)

      return 200
    end

    private def event_name(github_event_name)
      "github.#{github_event_name}"
    end
  end
end
