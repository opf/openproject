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

module OpenProject::Webhooks
  class Engine < ::Rails::Engine
    engine_name :openproject_webhooks

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-webhooks",
             bundled: true,
             author_url: "https://www.openproject.org" do
      menu :admin_menu,
           :plugin_webhooks,
           { controller: "/webhooks/outgoing/admin", action: :index },
           if: Proc.new { User.current.admin? },
           parent: :api_and_webhooks,
           caption: :"webhooks.plural"
    end

    initializer "webhooks.subscribe_to_notifications" do |app|
      app.config.after_initialize do
        ::OpenProject::Webhooks::EventResources.subscribe!
      end
    end

    add_cron_jobs do
      {
        CleanupWebhookLogsJob: {
          cron: "28 5 * * 7", # runs at 5:28 on Sunday
          class: ::CleanupWebhookLogsJob.name
        }
      }
    end
  end
end
