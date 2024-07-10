# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
class Submenu
  include Rails.application.routes.url_helpers
  attr_reader :view_type, :project, :params

  def initialize(view_type:, project: nil, params: nil)
    @view_type = view_type
    @project = project
    @params = params
  end

  def menu_items
    [
      OpenProject::Menu::MenuGroup.new(header: I18n.t("js.label_starred_queries"), children: starred_queries),
      OpenProject::Menu::MenuGroup.new(header: I18n.t("js.label_default_queries"), children: default_queries),
      OpenProject::Menu::MenuGroup.new(header: I18n.t("js.label_global_queries"), children: global_queries),
      OpenProject::Menu::MenuGroup.new(header: I18n.t("js.label_custom_queries"), children: custom_queries)
    ]
  end

  def starred_queries
    base_query
      .where("starred" => "t")
      .pluck(:id, :name)
      .map { |id, name| menu_item(name, query_params(id)) }
      .sort_by(&:title)
  end

  def default_queries
    raise NotImplementedError
  end

  def global_queries
    base_query
      .where("starred" => "f")
      .where("public" => "t")
      .pluck(:id, :name)
      .map { |id, name| menu_item(name, query_params(id)) }
      .sort_by(&:title)
  end

  def custom_queries
    base_query
      .where("starred" => "f")
      .where("public" => "f")
      .pluck(:id, :name)
      .map { |id, name| menu_item(name, query_params(id)) }
      .sort_by(&:title)
  end

  def base_query
    base_query ||= Query
                     .visible(User.current)
                     .includes(:project)
                     .joins(:views)
                     .where("views.type" => view_type)

    if project.present?
      base_query.where("queries.project_id" => project.id)
    else
      base_query.where("queries.project_id" => nil)
    end
  end

  def query_params(id)
    { query_id: id }
  end

  def menu_item(name, query_params)
    OpenProject::Menu::MenuItem.new(title: name,
                                    href: query_path(query_params),
                                    selected: selected?(query_params),
                                    favored: favored?(query_params))
  end

  def selected?(query_params)
    query_params.each_key do |filter_key|
      if params[filter_key] != query_params[filter_key].to_s
        return false
      end
    end

    if query_params.empty? && (%i[filters query_props query_id name].any? { |k| params.key? k })
      return false
    end

    true
  end

  def favored?(_query_params)
    false
  end

  def query_path(query_params)
    raise NotImplementedError
  end
end
