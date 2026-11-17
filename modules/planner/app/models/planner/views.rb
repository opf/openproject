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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Planner
  # The default view's paths and forms go without a view name.
  module Views
    Definition = Data.define(:name, :model, :component, :icon, :sortable, :filterable) do
      def title = I18n.t("planner.views.#{name}")

      def default? = equal?(Views.default)

      def sortable? = sortable

      def filterable? = filterable

      def param = (name unless default?)

      def path(**query)
        url_helpers = Rails.application.routes.url_helpers
        default? ? url_helpers.planner_path(**query) : url_helpers.planner_view_path(name, **query)
      end

      def build_component(user:, project:, adding: nil, filter: View::FILTERS.first)
        component.new(model.new(user:, project:), view: self, adding:, filter:)
      end
    end

    ALL = [
      Definition.new(name: "today", model: Today, component: TodayComponent, icon: :sun,
                     sortable: true, filterable: true),
      Definition.new(name: "upcoming", model: Upcoming, component: UpcomingComponent, icon: :calendar,
                     sortable: true, filterable: true),
      Definition.new(name: "overdue", model: Overdue, component: OverdueComponent, icon: :alert,
                     sortable: false, filterable: false),
      Definition.new(name: "completed", model: Completed, component: CompletedComponent, icon: :"check-circle",
                     sortable: false, filterable: false)
    ].freeze

    def self.default = ALL.first

    def self.names = ALL.map(&:name)

    def self.fetch(name) = ALL.find { it.name == name.to_s } || default
  end
end
