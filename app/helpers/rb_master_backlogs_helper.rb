#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Team
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

module RbMasterBacklogsHelper
  unloadable

  include Redmine::I18n

  def render_backlog_menu(backlog)
    content_tag(:div, :class => 'menu') do
      [
        content_tag(:div, '', :class => "ui-icon ui-icon-carat-1-s"),
        content_tag(:ul, :class => 'items') do

          backlog_menu_items_for(backlog).map do |item|
            content_tag(:li, item, :class => 'item')
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
    [:new_story, :stories_tasks, :task_board, :burndown, :cards, :wiki].each do |key|
      menu << items[key] if items.keys.include?(key)
    end

    menu
  end

  def common_backlog_menu_items_for(backlog)
    items = {}

    items[:new_story] = content_tag(:a,
                                    l('backlogs.add_new_story'),
                                    :href => '#',
                                    :class => 'add_new_story')

    items[:stories_tasks] = link_to(l(:label_stories_tasks),
                                    :controller => '/rb_queries',
                                    :action => 'show',
                                    :project_id => @project,
                                    :sprint_id => backlog.sprint)

    if OpenProject::Backlogs::TaskboardCard::PageLayout.selected_label.present?
      items[:cards] = link_to(l(:label_sprint_cards),
                              :controller => '/rb_stories',
                              :action => 'index',
                              :project_id => @project,
                              :sprint_id => backlog.sprint,
                              :format => :pdf)
    end

    items
  end

  def sprint_backlog_menu_items_for(backlog)
    items = {}

    items[:task_board] = link_to(l(:label_task_board),
                                 :controller => '/rb_taskboards',
                                 :action => 'show',
                                 :project_id => @project,
                                 :sprint_id => backlog.sprint)

    if backlog.sprint.has_burndown?
      items[:burndown] = content_tag(:a,
                                     l('backlogs.show_burndown_chart'),
                                     :href => '#',
                                     :class => 'show_burndown_chart')
    end

    if @project.module_enabled? "wiki"
      items[:wiki] = link_to(l(:label_wiki),
                             :controller => '/rb_wikis',
                             :action => 'edit',
                             :project_id => @project,
                             :sprint_id => backlog.sprint)
    end

    items
  end
end
