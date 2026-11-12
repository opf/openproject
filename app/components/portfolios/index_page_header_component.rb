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

module Portfolios
  class IndexPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    attr_accessor :current_user,
                  :query,
                  :state,
                  :params

    STATE_DEFAULT = :show

    delegate :projects_query_params, to: :helpers

    def initialize(current_user:, query:, params:)
      super

      self.current_user = current_user
      self.query = query
      self.state = STATE_DEFAULT
      self.params = params
    end

    def self.wrapper_key
      "portfolios-index-page-header"
    end

    def page_title
      query.name || t(:label_portfolio_plural)
    end

    def breadcrumb_items
      [
        { href: portfolios_path, text: t(:label_portfolio_plural), skip_for_mobile: first_menu_item? },
        current_breadcrumb_element
      ]
    end

    def current_breadcrumb_element
      return page_title if query.name.blank?

      if current_section && current_section.header.present?
        helpers.nested_breadcrumb_element(current_section.header, query.name)
      else
        page_title
      end
    end

    def current_section
      return @current_section if defined?(@current_section)

      @current_section = Portfolios::Menu
                           .new(controller_path:, params:, current_user:)
                           .selected_menu_group
    end

    def first_menu_item?
      current_item = current_section&.children&.select { |x| x.selected == true }&.first
      current_item&.title == ::ProjectQueries::Static.query(ProjectQueries::Static::ACTIVE_PORTFOLIOS).name
    end
  end
end
