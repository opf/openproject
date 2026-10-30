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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module OpenProject::ITSM
  class Engine < ::Rails::Engine
    engine_name :openproject_itsm

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "openproject_itsm.inflections" do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym "ITSM"
      end
    end

    class_inflection_override("itsm" => "ITSM")

    initializer "openproject_itsm.feature_decisions" do
      OpenProject::FeatureDecisions.add :helpdesk,
                                        description: "Enables help desk features (incoming email mailboxes per project)."
    end

    initializer "openproject_itsm.configuration" do
      ::Settings::Definition.add :helpdesk_enabled,
                                 description: "Enables/disables help desk functionality.",
                                 writable: true,
                                 default: false,
                                 format: :boolean
    end

    register "openproject-itsm", author_url: "https://www.openproject.org", bundled: true do
      project_module :helpdesk, if: -> { OpenProject::FeatureDecisions.helpdesk_active? } do
        permission :manage_helpdesk,
                   {},
                   permissible_on: :project,
                   require: :member
      end

      menu :admin_menu,
           :helpdesk,
           { controller: "/itsm/admin/settings", action: "show" },
           caption: :label_helpdesk,
           after: :api_and_webhooks,
           icon: :"op-life-ring",
           if: ->(_) { User.current.admin? && OpenProject::FeatureDecisions.helpdesk_active? }
    end

    include_module "Projects::HelpdeskMailboxes", into: "Project"
  end
end
