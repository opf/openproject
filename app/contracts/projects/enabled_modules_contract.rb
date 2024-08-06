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

module Projects
  class EnabledModulesContract < ModelContract
    validate :validate_permission
    validate :validate_dependencies_met

    protected

    def validate_model?
      false
    end

    def validate_permission
      errors.add :base, :error_unauthorized unless user.allowed_in_project?(:select_project_modules, model)
    end

    def validate_dependencies_met
      enabled_modules_with_dependencies
        .each do |mod|
        (mod[:dependencies] - model.enabled_module_names.map(&:to_sym)).each do |dep|
          errors.add(:enabled_modules,
                     :dependency_missing,
                     dependency: I18n.t("project_module_#{dep}"),
                     module: I18n.t("project_module_#{mod[:name]}"))
        end
      end
    end

    def enabled_modules_with_dependencies
      OpenProject::AccessControl
        .modules
        .select { |m| model.enabled_module_names.include?(m[:name].to_s) && m[:dependencies] }
    end
  end
end
