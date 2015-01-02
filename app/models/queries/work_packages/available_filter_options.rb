#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Queries::WorkPackages::AvailableFilterOptions
  def available_work_package_filters
    return @available_work_package_filters if @available_work_package_filters

    setup_available_work_package_filters

    add_visible_projects_options unless project || visible_projects.empty?
    add_user_options

    @available_work_package_filters = if project
                                        add_project_options
                                      else
                                        add_global_options
    end

    @available_work_package_filters
  end

  def work_package_filter_available?(key)
    available_work_package_filters.has_key?(key.to_s)
  end

  def get_custom_field_options(custom_fields)
    filters = {}
    custom_fields.select(&:is_filter?).each do |field|
      case field.field_format
      when 'int', 'float'
        options = { type: :integer, order: 20 }
      when 'text'
        options = { type: :text, order: 20 }
      when 'list'
        options = { type: :list_optional, values: field.possible_values, order: 20 }
      when 'date'
        options = { type: :date, order: 20 }
      when 'bool'
        options = { type: :list, values: [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], order: 20 }
      when 'user', 'version'
        next unless project
        options = { type: :list_optional, values: field.possible_values_options(project), order: 20 }
      else
        options = { type: :string, order: 20 }
      end
      filters["cf_#{field.id}"] = options.merge(name: field.name)
    end
    filters
  end

  private

  def visible_projects
    @visible_projects ||= Project.visible.all
  end

  def get_principals
    if project
      project.principals.sort
    elsif visible_projects.any?
      # members of visible projects
      principals = Principal.active.where(["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", visible_projects.map(&:id)]).sort
    else
      []
    end
  end

  # options for available filters

  def setup_available_work_package_filters
    types = project.nil? ? Type.find(:all, order: 'position') : project.rolled_up_types

    @available_work_package_filters = {
      status_id:       { type: :list_status, order: 1, values: Status.all.map { |s| [s.name, s.id.to_s] } },
      type_id:         { type: :list, order: 2, values: types.map { |s| [s.name, s.id.to_s] } },
      priority_id:     { type: :list, order: 3, values: IssuePriority.all.map { |s| [s.name, s.id.to_s] } },
      subject:         { type: :text, order: 8 },
      created_at:      { type: :date_past, order: 9 },
      updated_at:      { type: :date_past, order: 10 },
      start_date:      { type: :date, order: 11 },
      due_date:        { type: :date, order: 12 },
      estimated_hours: { type: :integer, order: 13 },
      done_ratio:      { type: :integer, order: 14 }
    }.with_indifferent_access

    add_readable_names_to_work_package_filters @available_work_package_filters
  end

  def add_readable_names_to_work_package_filters(work_package_filters)
    work_package_filters.tap do |filters|
      filters.each do |name, filter|
        filter.merge! name: WorkPackage.human_attribute_name(name)
      end
    end
  end

  def add_visible_projects_options
    # project filter
    project_values = []
    Project.project_tree(visible_projects) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      project_values << ["#{prefix}#{p.name}", p.id.to_s]
    end
    @available_work_package_filters['project_id'] = { type: :list, order: 1, values: project_values } unless project_values.empty?
  end

  def add_project_options
    # project specific filters
    categories = project.categories.all
    unless categories.empty?
      @available_work_package_filters['category_id'] = { type: :list_optional, order: 6, values: categories.map { |s| [s.name, s.id.to_s] } }
    end
    versions = project.shared_versions.all
    unless versions.empty?
      @available_work_package_filters['fixed_version_id'] = { type: :list_optional, order: 7, values: versions.sort.map { |s| ["#{s.project.name} - #{s.name}", s.id.to_s] }, name: WorkPackage.human_attribute_name('fixed_version_id') }
    end
    unless project.leaf?
      subprojects = project.descendants.visible.all
      unless subprojects.empty?
        @available_work_package_filters['subproject_id'] = { type: :list_subprojects, order: 13, values: subprojects.map { |s| [s.name, s.id.to_s] }, name: I18n.t('query_fields.subproject_id') }
      end
    end
    add_custom_fields_options(project.all_work_package_custom_fields)
  end

  def add_user_options
    principals_by_class = get_principals.group_by(&:class)

    user_values = principals_by_class[User].present? ?
                    principals_by_class[User].map { |s| [s.name, s.id.to_s] }.sort :
                    []

    group_values = Setting.work_package_group_assignment? && principals_by_class[Group].present? ?
                      principals_by_class[Group].map { |s| [s.name, s.id.to_s] }.sort :
                      []

    assigned_to_values = (user_values + group_values).sort
    assigned_to_values = [["<< #{l(:label_me)} >>", 'me']] + assigned_to_values if User.current.logged?
    @available_work_package_filters['assigned_to_id'] = { type: :list_optional, order: 4, values: assigned_to_values, name: WorkPackage.human_attribute_name('assigned_to_id') } unless assigned_to_values.empty?

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    author_values += user_values
    @available_work_package_filters['author_id'] = { type: :list, order: 5, values: author_values, name: WorkPackage.human_attribute_name('author_id') } unless author_values.empty?

    group_values = Group.all.map { |g| [g.name, g.id.to_s] }
    @available_work_package_filters['member_of_group'] = { type: :list_optional, order: 6, values: group_values, name: I18n.t('query_fields.member_of_group') } unless group_values.empty?

    role_values = Role.givable.map { |r| [r.name, r.id.to_s] }
    @available_work_package_filters['assigned_to_role'] = { type: :list_optional, order: 7, values: role_values, name: I18n.t('query_fields.assigned_to_role') } unless role_values.empty?

    responsible_values = user_values.dup
    responsible_values = [["<< #{l(:label_me)} >>", 'me']] + responsible_values if User.current.logged?
    @available_work_package_filters['responsible_id'] = { type: :list_optional, order: 4, values: responsible_values, name: WorkPackage.human_attribute_name('responsible_id') } unless responsible_values.empty?

    # watcher filters
    if User.current.logged?
      # populate the watcher list with the same user list as other user filters if the user has the :view_work_package_watchers permission in at least one project
      # TODO: this could be differentiated more, e.g. all users could watch issues in public projects, but won't necessarily be shown here
      watcher_values = [["<< #{l(:label_me)} >>", 'me']]
      user_values.each { |v| watcher_values << v } if User.current.allowed_to_globally?(:view_work_packages_watchers, {})
      @available_work_package_filters['watcher_id'] = { type: :list, order: 15, values: watcher_values, name: WorkPackage.human_attribute_name('watcher_id') }
    end
  end

  def add_global_options
    # global filters for cross project issue list
    system_shared_versions = Version.visible.find_all_by_sharing('system')
    unless system_shared_versions.empty?
      @available_work_package_filters['fixed_version_id'] = { type: :list_optional, order: 7, values: system_shared_versions.sort.map { |s| ["#{s.project.name} - #{s.name}", s.id.to_s] }, name: WorkPackage.human_attribute_name('fixed_version_id') }
    end
    add_custom_fields_options(WorkPackageCustomField.find(:all, conditions: { is_filter: true, is_for_all: true }))
  end

  def add_custom_fields_options(custom_fields)
    available_work_package_filters # compute default available_work_package_filters
    return available_work_package_filters if available_work_package_filters.any? { |key, _| key.starts_with? 'cf_' }

    @available_work_package_filters.merge(get_custom_field_options(custom_fields))
  end
end
