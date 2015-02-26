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

module ProjectsHelper
  include WorkPackagesFilterHelper

  def link_to_version(version, html_options = {}, options = {})
    return '' unless version && version.is_a?(Version)
    link_to_if version.visible?, options[:before_text].to_s.html_safe + format_version_name(version), { controller: '/versions', action: 'show', id: version }, html_options
  end

  def project_settings_tabs
    tabs = [{ name: 'info', action: :edit_project, partial: 'projects/edit', label: :label_information_plural },
            { name: 'modules', action: :select_project_modules, partial: 'projects/settings/modules', label: :label_module_plural },
            { name: 'members', action: :manage_members, partial: 'projects/settings/members', label: :label_member_plural },
            { name: 'versions', action: :manage_versions, partial: 'projects/settings/versions', label: :label_version_plural },
            { name: 'categories', action: :manage_categories, partial: 'projects/settings/categories', label: :label_work_package_category_plural },
            { name: 'repository', action: :manage_repository, partial: 'projects/settings/repository', label: :label_repository },
            { name: 'boards', action: :manage_boards, partial: 'projects/settings/boards', label: :label_board_plural },
            { name: 'activities', action: :manage_project_activities, partial: 'projects/settings/activities', label: :enumeration_activities },
            { name: 'types', action: :manage_types, partial: 'projects/settings/types', label: :'label_type_plural' }
           ]
    tabs.select { |tab| User.current.allowed_to?(tab[:action], @project) }
  end

  # Renders a tree of projects as a nested set of unordered lists
  # The given collection may be a subset of the whole project tree
  # (eg. some intermediate nodes are private and can not be seen)
  def render_project_hierarchy(projects)
    s = ''
    if projects.any?
      ancestors = []
      original_project = @project
      Project.project_tree(projects) do |project, _level|
        # set the project environment to please macros.
        @project = project
        if ancestors.empty? || project.is_descendant_of?(ancestors.last)
          s << "<ul class='projects #{ ancestors.empty? ? 'root' : nil}'>\n"
        else
          ancestors.pop
          s << '</li>'
          while ancestors.any? && !project.is_descendant_of?(ancestors.last)
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        classes = (ancestors.empty? ? 'root' : 'child')
        s << "<li class='#{classes}'><div class='#{classes}'>" +
          link_to_project(project, {}, { class: 'project' }, true)
        s << "<div class='wiki description'>#{format_text(project.short_description, project: project)}</div>" unless project.description.blank?
        s << "</div>\n"
        ancestors << project
      end
      s << ("</li></ul>\n" * ancestors.size)
      @project = original_project
    end
    s.html_safe
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
end
