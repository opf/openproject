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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module CostTypes
    class EditFormHeaderComponent < ApplicationComponent
      def initialize(cost_type:, selected:, **)
        @cost_type = cost_type
        @selected = selected
        super(cost_type, **)
      end

      def tabs
        [
          {
            name: "edit",
            path: edit_admin_cost_type_path(@cost_type),
            label: t(:label_details)
          },
          {
            name: "rates",
            path: rates_admin_cost_type_path(@cost_type),
            label: t("cost_types.admin.rates.title")
          },
          {
            name: "cost_type_projects",
            path: admin_cost_type_projects_path(@cost_type),
            label: t(:label_project_plural)
          }
        ]
      end

      private

      def page_title
        @cost_type.persisted? ? @cost_type.name : "#{t(:label_new)} #{::CostType.model_name.human}"
      end

      def breadcrumbs_items
        [
          { href: admin_index_path, text: t(:label_administration) },
          { href: admin_cost_types_path, text: t(:label_cost_type_plural) },
          page_title
        ]
      end
    end
  end
end
