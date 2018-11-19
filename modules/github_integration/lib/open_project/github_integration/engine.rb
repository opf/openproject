#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require 'open_project/plugins'
# require 'open_project/notifications'

module OpenProject::GithubIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_github_integration

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-github_integration',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.1.0pre1'


    initializer 'github.register_hook' do
      ::OpenProject::Webhooks.register_hook 'github' do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer 'github.subscribe_to_notifications' do
      ::OpenProject::Notifications.subscribe('github.pull_request',
                                             &NotificationHandlers.method(:pull_request))
      ::OpenProject::Notifications.subscribe('github.issue_comment',
                                             &NotificationHandlers.method(:issue_comment))
    end

  end
end
