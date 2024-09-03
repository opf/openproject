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

module RbMasterBacklogsHelper
  include Redmine::I18n

  def render_backlog_menu(backlog)
    # associated javascript defined in taskboard.js
    content_tag(:div, class: "backlog-menu") do
      [
        content_tag(:div, "", class: "menu-trigger icon-context icon-pulldown icon-small"),
        content_tag(:ul, class: "items") do
          backlog_menu_items_for(backlog).map do |item|
            content_tag(:li, item, class: "item")
          end.join.html_safe
        end
      ].join.html_safe
    end
  end

  def backlog_menu_items_for(backlog)
    items = common_backlog_menu_items_for(backlog)

    if backlog.sprint_backlog?
      items.merge!(sprint_backlog_menu_items_for(backlog))
    end

    menu = []
    %i[new_story stories_tasks task_board burndown cards wiki configs properties].each do |key|
      menu << items[key] if items.keys.include?(key)
    end

    menu
  end

  def common_backlog_menu_items_for(backlog)
    items = {}

    if current_user.allowed_in_project?(:add_work_packages, @project)
      items[:new_story] = content_tag(:a,
                                      I18n.t("backlogs.add_new_story"),
                                      href: "#",
                                      class: "add_new_story")
    end

    items[:stories_tasks] = link_to(I18n.t(:label_stories_tasks),
                                    controller: "/rb_queries",
                                    action: "show",
                                    project_id: @project,
                                    sprint_id: backlog.sprint)

    if current_user.allowed_in_project?(:manage_versions, @project)
      items[:properties] = properties_link(backlog)
    end

    items
  end

  def properties_link(backlog)
    back_path = backlogs_project_backlogs_path(@project)

    version_path = edit_version_path(backlog.sprint, back_url: back_path, project_id: @project.id)

    link_to(I18n.t(:"backlogs.properties"), version_path)
  end

  def sprint_backlog_menu_items_for(backlog)
    items = {}

    if current_user.allowed_in_project?(:view_taskboards, @project)
      items[:task_board] = link_to(I18n.t(:label_task_board),
                                   { controller: "/rb_taskboards",
                                     action: "show",
                                     project_id: @project,
                                     sprint_id: backlog.sprint },
                                   class: "show_task_board")
    end

    if backlog.sprint.has_burndown?
      items[:burndown] = content_tag(:a,
                                     I18n.t("backlogs.show_burndown_chart"),
                                     href: "#",
                                     class: "show_burndown_chart")
    end

    if @project.module_enabled? "wiki"
      items[:wiki] = link_to(I18n.t(:label_wiki),
                             controller: "/rb_wikis",
                             action: "edit",
                             project_id: @project,
                             sprint_id: backlog.sprint)
    end

    items
  end
end
