# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Members::IndexPageHeaderComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include ApplicationHelper

  def initialize(project: nil)
    super
    @project = project
  end

  def breadcrumb_items
    [{ href: project_overview_path(@project.id), text: @project.name },
     { href: project_members_path(@project), text: I18n.t(:label_member_plural), skip_for_mobile: first_menu_item? },
     current_breadcrumb_element]
  end

  def page_title
    # Rework this, when the Members page actually works with queries
    @query ||= current_query
    query_name = @query[:query_name]

    if @query && query_name
      query_name
    else
      t(:label_member_plural)
    end
  end

  def current_breadcrumb_element
    # Rework this, when the Members page actually works with queries
    @query ||= current_query
    query_name = @query[:query_name]
    menu_header = @query[:menu_header]

    if @query && query_name
      if menu_header.present?
        helpers.nested_breadcrumb_element(menu_header, query_name)
      else
        query_name
      end
    else
      t(:label_member_plural)
    end
  end

  def current_query
    query_name = nil
    query_href = nil
    menu_header = nil

    Members::Menu.new(project: @project, params:).menu_items.find do |section|
      section.children.find do |menu_query|
        if !!menu_query.selected
          query_name = menu_query.title
          query_href = menu_query.href
          menu_header = section.header
        end
      end
    end

    { query_name:, query_href:, menu_header: }
  end

  def first_menu_item?
    if current_query.present?
      return current_query[:query_href] == project_members_path(@project)
    end

    false
  end
end
