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
module Gantt
  class MenusController < ApplicationController
    before_action :find_optional_project

    def show
      @sidebar_menu_items = menu_items
      render layout: nil
    end

    private

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: I18n.t('js.label_starred_queries'), children: starred_queries),
        OpenProject::Menu::MenuGroup.new(header: I18n.t('js.label_default_queries'), children: default_queries),
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

    def default_queries
      query_generator = Gantt::DefaultQueryGeneratorService.new(with_project_context: @project.present?)
      queries = []
      Gantt::DefaultQueryGeneratorService::QUERY_OPTIONS.each do |query_key|
        queries << menu_item(
          :query_props,
          query_generator.call(query_key:),
          Gantt::DefaultQueryGeneratorService::QUERY_MAPPINGS[query_key]
        )
      end

      queries
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

    def menu_item(filter_key, filter_val, name)
      OpenProject::Menu::MenuItem.new(title: name,
                                      href: gantt_path(filter_key, filter_val),
                                      selected: selected?(filter_key, filter_val))
    end

    def selected?(filter_key, value)
      params[filter_key] == value.to_s
    end

    def gantt_path(filter_key, id)
      if @project.present?
        project_gantt_index_path(@project, params.permit(filter_key).merge!(filter_key => id))
      else
        gantt_index_path(params.permit(filter_key).merge!(filter_key => id))
      end
    end
  end
end
