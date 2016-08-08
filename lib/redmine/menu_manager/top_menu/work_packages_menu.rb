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

module Redmine::MenuManager::TopMenu::WorkPackagesMenu
   def render_work_packages_top_menu_node
    render_menu_dropdown_with_items(
      label: l(:label_work_package_plural),
      label_options: { id: 'work-packages-menu', class: 'icon5 icon-work-packages' },
      items: work_packages_items,
      options: {
        drop_down_class: 'drop-down--projects'
      }
    )
  end

  private

  def work_packages_items
    [work_packages_new_item,
      work_packages_all,
      work_packages_filter_assigned_to_me,
      work_packages_filter_reported_by_me,
      work_packages_filter_responsible_for,
      work_packages_filter_watched_by_me]
  end

  def work_packages_new_item
    Redmine::MenuManager::MenuItem.new(
      :new_work_package,
      { controller: '/work_packages', action: 'new', project_id: @project },
      caption: t(:label_work_package_new),
      html: {
        class: "icon-add icon4",
        accesskey: OpenProject::AccessKeys.key_for(:new_work_package)
      }
    )
  end

  def work_packages_all
    Redmine::MenuManager::MenuItem.new(
      :list_work_packages,
      { controller: '/work_packages', action: 'index' },
      caption: t(:label_work_package_view_all)
    )
  end

  def work_packages_filter_assigned_to_me
    Redmine::MenuManager::MenuItem.new(
      :work_packages_filter_assigned_to_me,
      work_packages_assigned_to_me_path,
      caption: t(:label_assigned_to_me_work_packages)
    )
  end

  def work_packages_filter_reported_by_me
    Redmine::MenuManager::MenuItem.new(
      :work_packages_filter_reported_by_me,
      work_packages_reported_by_me_path,
      caption: t(:label_reported_work_packages)
    )
  end

  def work_packages_filter_responsible_for
    Redmine::MenuManager::MenuItem.new(
      :work_packages_filter_responsible_for,
      work_packages_responsible_for_path,
      caption: t(:label_responsible_for_work_packages)
    )
  end

  def work_packages_filter_watched_by_me
    Redmine::MenuManager::MenuItem.new(
      :work_packages_filter_watched_by_me,
      work_packages_watched_path,
      caption: t(:label_watched_work_packages)
    )
  end
end