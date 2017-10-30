#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module ProjectsHelper
  include WorkPackagesFilterHelper

  def link_to_version(version, html_options = {}, options = {})
    return '' unless version && version.is_a?(Version)

    link_name = options[:before_text].to_s.html_safe + format_version_name(version)
    link_to_if version.visible?,
               link_name,
               { controller: '/versions', action: 'show', id: version },
               html_options
  end

  def project_settings_tabs
    tabs = [
      {
        name: 'info',
        action: :edit_project,
        partial: 'projects/edit',
        label: :label_information_plural
      },
      {
        name: 'modules',
        action: :select_project_modules,
        partial: 'projects/settings/modules',
        label: :label_module_plural
      },
      {
        name: 'custom_fields',
        action: :edit_project,
        partial: 'projects/settings/custom_fields',
        label: :label_custom_field_plural
      },
      {
        name: 'versions',
        action: :manage_versions,
        partial: 'projects/settings/versions',
        label: :label_version_plural
      },
      {
        name: 'categories',
        action: :manage_categories,
        partial: 'projects/settings/categories',
        label: :label_work_package_category_plural
      },
      {
        name: 'repository',
        action: :manage_repository,
        partial: 'repositories/settings',
        label: :label_repository
      },
      {
        name: 'boards',
        action: :manage_boards,
        partial: 'projects/settings/boards',
        label: :label_board_plural
      },
      {
        name: 'activities',
        action: :manage_project_activities,
        partial: 'projects/settings/activities',
        label: :enumeration_activities
      },
      {
        name: 'types',
        action: :manage_types,
        partial: 'projects/settings/types',
        label: :label_work_package_types
      }
    ]
    tabs.select { |tab| User.current.allowed_to?(tab[:action], @project) }
  end

  # Returns a set of options for a select field, grouped by project.
  def version_options_for_select(versions, selected = nil)
    grouped = Hash.new { |h, k| h[k] = [] }
    versions.each do |version|
      grouped[version.project.name] << [version.name, version.id]
    end

    # Add in the selected
    if selected && !versions.include?(selected)
      grouped[selected.project.name] << [selected.name, selected.id]
    end

    if grouped.keys.size > 1
      grouped_options_for_select(grouped, selected && selected.id)
    else
      options_for_select((grouped.values.first || []), selected && selected.id)
    end
  end

  def format_version_sharing(sharing)
    sharing = 'none' unless Version::VERSION_SHARINGS.include?(sharing)
    l("label_version_sharing_#{sharing}")
  end

  def filter_set?
    if params[:filters].present?
      true
    else
      false
    end
  end

  def allowed_filters(query)
    filters_static = %i(status name_and_identifier)
    filters_dynamic = []
    if EnterpriseToken.allows_to?(:custom_fields_in_projects_list)
      filters_dynamic = ProjectCustomField
                          .where("field_format <> 'version'")
                          .order(:name)
                          .pluck(:id)
                          .map do |id|
                            "cf_#{id}".to_sym
                            end
    end

    filters = filters_static + filters_dynamic

    unless User.current.admin?
      filters = filters - admin_only_filters
    end

    filter_instances = filters.map do |name|
      query.find_available_filter(name)
    end

    filter_instances.sort_by { |filter| filter.human_name }
  end

  def admin_only_filters
    []
  end
end
