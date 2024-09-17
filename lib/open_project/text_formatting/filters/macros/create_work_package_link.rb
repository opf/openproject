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

module OpenProject::TextFormatting::Filters::Macros
  module CreateWorkPackageLink
    class << self
      include OpenProject::StaticRouting::UrlHelpers
    end

    HTML_CLASS = "create_work_package_link".freeze

    module_function

    def identifier
      HTML_CLASS
    end

    def apply(macro, result:, context:)
      macro.replace work_package_link(macro, context)
    end

    def work_package_link(macro, context)
      project = context[:project]
      raise I18n.t("macros.create_work_package_link.errors.no_project_context") if project.nil?

      type_name = macro["data-type"]
      class_name = macro["data-classes"] == "button" ? "button" : nil

      if type_name.present?
        type = project.types.find_by(name: type_name)
        if type.nil?
          raise I18n.t(
            "macros.create_work_package_link.errors.invalid_type",
            type: type_name,
            project: project.name
          )
        end

        ApplicationController.helpers.link_to(
          I18n.t("macros.create_work_package_link.link_name_type", type_name:),
          new_project_work_packages_path(project_id: project.identifier, type: type.id),
          class: class_name
        )
      else
        ApplicationController.helpers.link_to(
          I18n.t("macros.create_work_package_link.link_name"),
          new_project_work_packages_path(project_id: project.identifier),
          class: class_name
        )
      end
    end
  end
end
