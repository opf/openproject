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

module Workflows
  module Index
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :name, :types_and_variants, :roles, :projects
      main_column :name
      mobile_labels :types_and_variants, :roles, :projects

      def initialize(workflows:, variants:, role_counts:, filtered: false)
        super(rows: workflows)

        @variants = variants
        @role_counts = role_counts
        @filtered = filtered
      end

      def mobile_title = I18n.t(:label_workflow_plural)

      def row_class = RowComponent

      def pagination_params = { allowed_params: %w[filters] }

      def headers
        [
          [:name, { caption: I18n.t("workflows.index.columns.name") }],
          [:types_and_variants, { caption: I18n.t("workflows.index.columns.types_and_variants") }],
          [:roles, { caption: I18n.t("workflows.index.columns.roles") }],
          [:projects, { caption: I18n.t("workflows.index.columns.projects") }]
        ]
      end

      def has_actions? = true

      def variants_for(workflow) = @variants.fetch(workflow.id, [])

      def role_count_for(workflow) = @role_counts.fetch(workflow.id, 0)

      def blank_title
        @filtered ? I18n.t("workflows.index.blank_slate.filtered_title") : I18n.t("workflows.index.blank_slate.title")
      end

      def blank_description
        if @filtered
          I18n.t("workflows.index.blank_slate.filtered_description")
        else
          I18n.t("workflows.index.blank_slate.description")
        end
      end

      def blank_icon = :workflow
    end
  end
end
