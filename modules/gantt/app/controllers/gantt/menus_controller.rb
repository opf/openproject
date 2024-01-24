# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++
module ::Gantt
  class MenusController < ApplicationController
    before_action :find_optional_project

    def show
      @sidebar_menu_items = first_level_menu_items + nested_menu_items
      render layout: nil
    end

    private

    def first_level_menu_items
      []
    end

    def nested_menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: I18n.t('js.label_starred_queries'), children: starred_queries),
        OpenProject::Menu::MenuGroup.new(header: I18n.t('js.label_default_queries'), children: []),
        OpenProject::Menu::MenuGroup.new(header: I18n.t('js.label_global_queries'), children: global_queries),
        OpenProject::Menu::MenuGroup.new(header: I18n.t('js.label_custom_queries'), children: custom_queries)
      ]
    end

    def starred_queries
      base_query
        .where('starred' => 't')
        .pluck(:id, :name)
        .map { |id, name| menu_item(:query_id, id, name) }
    end

    def global_queries
      base_query
        .where('starred' => 'f')
        .where('public' => 't')
        .pluck(:id, :name)
        .map { |id, name| menu_item(:query_id, id, name) }
    end

    def custom_queries
      base_query
        .where('starred' => 'f')
        .where('public' => 'f')
        .pluck(:id, :name)
        .map { |id, name| menu_item(:query_id, id, name) }
    end

    def base_query
      base_query ||= Query
                     .visible(current_user)
                     .joins(:views, :project)
                     .where('views.type' => 'gantt')

      if @project.present?
        base_query = base_query.where('queries.project_id' => @project.id)
      end

      base_query
    end

    def menu_item(filter_key, id, name)
      OpenProject::Menu::MenuItem.new(title: name,
                                      href: gantt_path(filter_key, id),
                                      selected: selected?(filter_key, id))
    end

    def selected?(filter_key, value)
      return false if active_filter_count > 1

      params[filter_key] == value.to_s
    end

    def active_filter_count
      @active_filter_count ||= params[:filters].present? ? params[:filters].count : 0
    end

    def gantt_path(filter_key, id)
      @project.present? ? project_gantt_index_path(@project, filter_key => id) : gantt_index_path(filter_key => id)
    end
  end
end
