#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
        partial: 'project_settings/modules',
        label: :label_module_plural
      },
      {
        name: 'custom_fields',
        action: :edit_project,
        partial: 'project_settings/custom_fields',
        label: :label_custom_field_plural
      },
      {
        name: 'versions',
        action: :manage_versions,
        partial: 'project_settings/versions',
        label: :label_version_plural
      },
      {
        name: 'categories',
        action: :manage_categories,
        partial: 'project_settings/categories',
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
        partial: 'project_settings/boards',
        label: :label_board_plural
      },
      {
        name: 'activities',
        action: :manage_project_activities,
        partial: 'project_settings/activities',
        label: :enumeration_activities
      },
      {
        name: 'types',
        action: :manage_types,
        partial: 'project_settings/types',
        label: :label_work_package_types
      }
    ]
    tabs.select { |tab| User.current.allowed_to?(tab[:action], @project) }
  end

  # Returns a set of options for a select field, grouped by project.
  def version_options_for_select(versions, selected = nil)
    grouped = Hash.new { |h, k| h[k] = [] }
    (versions + [selected]).compact.uniq.each do |version|
      grouped[version.project.name] << [version.name, version.id]
    end

    if grouped.size > 1
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
    params[:filters].present?
  end

  def allowed_filters(query)
    query
      .available_filters
      .reject { |f| blacklisted_project_filter?(f) }
      .sort_by(&:human_name)
  end

  def blacklisted_project_filter?(filter)
    blacklist = [Queries::Projects::Filters::AncestorFilter]
    blacklist << Queries::Filters::Shared::CustomFields::Base unless EnterpriseToken.allows_to?(:custom_fields_in_projects_list)

    blacklist.detect { |clazz| filter.is_a? clazz }
  end

  def no_projects_result_box_params
    if User.current.allowed_to?(:add_project, nil, global: true)
      { action_url: new_project_path, display_action: true }
    else
      {}
    end
  end

  def project_more_menu_items(project)
    [project_more_menu_subproject_item(project),
     project_more_menu_settings_item(project),
     project_more_menu_archive_item(project),
     project_more_menu_unarchive_item(project),
     project_more_menu_copy_item(project),
     project_more_menu_delete_item(project)].compact
  end

  def project_more_menu_subproject_item(project)
    if User.current.allowed_to? :add_subprojects, project
      [t(:label_subproject_new),
       new_project_path(parent_id: project),
       class: 'icon-context icon-add',
       title: t(:label_subproject_new)]
    end
  end

  def project_more_menu_settings_item(project)
    if User.current.allowed_to?({ controller: '/project_settings', action: 'show' }, project)
      [t(:label_project_settings),
       { controller: '/project_settings', action: 'show', id: project },
       class: 'icon-context icon-settings',
       title: t(:label_project_settings)]
    end
  end

  def project_more_menu_archive_item(project)
    if User.current.admin? && project.active?
      [t(:button_archive),
       archive_project_path(project, status: params[:status]),
       data: { confirm: t('project.archive.are_you_sure', name: project.name) },
       method: :put,
       class: 'icon-context icon-locked',
       title: t(:button_archive)]
    end
  end

  def project_more_menu_unarchive_item(project)
    if User.current.admin? && !project.active? && (project.parent.nil? || project.parent.active?)
      [t(:button_unarchive),
       unarchive_project_path(project, status: params[:status]),
       method: :put,
       class: 'icon-context icon-unlocked',
       title: t(:button_unarchive)]
    end
  end

  def project_more_menu_copy_item(project)
    if User.current.allowed_to?(:copy_projects, project) && !project.archived?
      [t(:button_copy),
       copy_from_project_path(project, :admin),
       class: 'icon-context icon-copy',
       title: t(:button_copy)]
    end
  end

  def project_more_menu_delete_item(project)
    if User.current.admin
      [t(:button_delete),
       confirm_destroy_project_path(project),
       class: 'icon-context icon-delete',
       title: t(:button_delete)]
    end
  end

  def shorten_text(text, length)
    text.to_s.gsub(/\A(.{#{length}[^\n\r]*).*\z/m, '\1...').strip
  end

  def projects_with_level(projects)
    ancestors = []

    projects.each do |project|
      while !ancestors.empty? && !project.is_descendant_of?(ancestors.last)
        ancestors.pop
      end

      yield project, ancestors.count

      ancestors << project
    end
  end

  def project_css_classes(project)
    s = 'project'

    s << ' root' if project.root?
    s << ' child' if project.child?
    s << (project.leaf? ? ' leaf' : ' parent')

    s
  end

  def projects_with_levels_order_sensitive(projects, &block)
    if sorted_by_lft?
      project_tree(projects, &block)
    else
      projects_with_level(projects, &block)
    end
  end

  # Just like sort_header tag but removes sorting by
  # lft from the sort criteria as lft is mutually exclusive with
  # the other criteria.
  def projects_sort_header_tag(*args)
    former_criteria = @sort_criteria.criteria.dup

    @sort_criteria.criteria.reject! { |a, _| a == 'lft' }

    sort_header_tag(*args)
  ensure
    @sort_criteria.criteria = former_criteria
  end

  def deactivate_class_on_lft_sort
    if sorted_by_lft?
      '-inactive'
    end
  end

  def href_only_when_not_sort_lft
    unless sorted_by_lft?
      "href=#{projects_path(sortBy: JSON::dump([['lft', 'asc']]))}"
    end
  end

  def sorted_by_lft?
    @sort_criteria.first_key == 'lft'
  end
end
