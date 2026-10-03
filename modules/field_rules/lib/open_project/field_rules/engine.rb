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
# frozen_string_literal: true

require "open_project/plugins"

module OpenProject::FieldRules
  class Engine < ::Rails::Engine
    engine_name :openproject_field_rules

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-field_rules",
             author_url: "https://www.openproject.org",
             bundled: true do
      menu :admin_menu,
           :field_rule_sets,
           { controller: "/admin/field_rule_sets", action: :index },
           if: ->(_) { User.current.admin? },
           caption: :"field_rules.plural",
           parent: :admin_work_packages

      menu :project_menu,
           :settings_field_rule_scheme,
           { controller: "/projects/settings/field_rule_scheme", action: :show },
           if: ->(project) { User.current.allowed_in_project?(:assign_field_rule_scheme, project) },
           caption: :"field_rules.project_settings.title",
           parent: :settings

      project_module nil do
        permission :assign_field_rule_scheme,
                   { "projects/settings/field_rule_scheme": %i[show update] },
                   permissible_on: :project,
                   require: :member
      end
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::FieldRules::FieldRuleSetsAPI
      mount ::API::V3::FieldRules::FieldRuleSchemesAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::FieldRules::ProjectFieldRulesAPI
    end

    add_api_path :field_rule_sets do
      "#{root}/field_rule_sets"
    end

    add_api_path :field_rule_set do |id|
      "#{field_rule_sets}/#{id}"
    end

    add_api_path :field_rule_schemes do
      "#{root}/field_rule_schemes"
    end

    add_api_path :field_rule_scheme do |id|
      "#{field_rule_schemes}/#{id}"
    end

    add_api_path :project_field_rule_scheme do |project_id|
      "#{project(project_id)}/field_rule_scheme"
    end

    add_api_path :project_type_field_rules do |project_id, type_id|
      "#{project(project_id)}/types/#{type_id}/field_rules"
    end

    config.to_prepare do
      OpenProject::FieldRules.assert_patch_targets!

      ::WorkPackages::BaseContract.prepend(OpenProject::FieldRules::ContractPatch)
      ::WorkPackages::SetAttributesService.prepend(OpenProject::FieldRules::SetAttributesServicePatch)
      ::API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter.prepend(OpenProject::FieldRules::SchemaPatch)
      OpenProject::FieldRules::Constraints.install
    end
  end
end
