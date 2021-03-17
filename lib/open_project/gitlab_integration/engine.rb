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

require 'open_project/plugins'
require_relative './notification_handlers'
require_relative './hook_handler'

module OpenProject::GitlabIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_gitlab_integration

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-gitlab_integration',
             :author_url => 'https://github.com/btey/openproject-gitlab-integration',
             bundled: true


    initializer 'gitlab.register_hook' do
      ::OpenProject::Webhooks.register_hook 'gitlab' do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer 'gitlab.subscribe_to_notifications' do
      ::OpenProject::Notifications.subscribe('gitlab.merge_request_hook',
                                             &NotificationHandlers.method(:merge_request_hook))
      ::OpenProject::Notifications.subscribe('gitlab.note_hook',
                                             &NotificationHandlers.method(:note_hook))
      ::OpenProject::Notifications.subscribe('gitlab.issue_hook',
                                             &NotificationHandlers.method(:issue_hook))
      ::OpenProject::Notifications.subscribe('gitlab.push_hook',
                                             &NotificationHandlers.method(:push_hook))
    end

  end
end
