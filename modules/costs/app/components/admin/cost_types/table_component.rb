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
    class TableComponent < ::TableComponent
      options status: "active"

      def columns
        if status == "locked"
          %i[name unit unit_plural current_rate deleted_at]
        else
          %i[name unit unit_plural current_rate active_projects default]
        end
      end

      def sortable_columns
        %i[name unit unit_plural]
      end

      def initial_sort
        %i[name asc]
      end

      def headers
        columns.map { |column| [column.to_s, { caption: header_caption(column) }] }
      end

      def sortable?
        true
      end

      def locked?
        status == "locked"
      end

      private

      def header_caption(column)
        case column
        when :name then CostType.model_name.human
        when :unit then CostType.human_attribute_name(:unit)
        when :unit_plural then CostType.human_attribute_name(:unit_plural)
        when :current_rate then CostType.human_attribute_name(:current_rate)
        when :active_projects then I18n.t("cost_types.admin.columns.active_projects")
        when :default then I18n.t(:caption_default)
        when :deleted_at then I18n.t(:caption_locked_on)
        end
      end
    end
  end
end
