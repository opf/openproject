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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  # What a variant configuration screen says about where it is. The paths need no help: the
  # project is a segment of the route being generated, filled in from the path already served.
  module VariantScopeHelper
    # rubocop:disable Rails/HelperInstanceVariable
    def variant_scope_project = @project
    # rubocop:enable Rails/HelperInstanceVariable

    # A project administrator cannot open administration's roots, so the trail starts elsewhere.
    def variant_scope_breadcrumb_roots
      return administration_breadcrumb_roots if variant_scope_project.nil?

      project = variant_scope_project
      [{ href: project_overview_path(project.id), text: project.name },
       { href: project_settings_general_path(project.id), text: I18n.t("label_project_settings") },
       { href: project_settings_work_packages_types_path(project), text: I18n.t(:label_work_package_plural) }]
    end

    # This route has no in_project_id segment to absorb the one the request carries, so it has to
    # be dropped or it rides along as a query parameter.
    def variant_scope_types_path
      return types_path if variant_scope_project.nil?

      project_settings_work_packages_types_path(variant_scope_project, in_project_id: nil)
    end

    # The layout appends the project itself, so naming it here would say it twice.
    def variant_scope_title
      return I18n.t(:label_administration) if variant_scope_project.nil?

      I18n.t("label_project_settings")
    end

    private

    def administration_breadcrumb_roots
      [{ href: admin_index_path, text: I18n.t("label_administration") },
       { href: admin_settings_work_packages_general_path, text: I18n.t(:label_work_package_plural) },
       { href: types_path, text: I18n.t(:label_type_plural) }]
    end
  end
end
