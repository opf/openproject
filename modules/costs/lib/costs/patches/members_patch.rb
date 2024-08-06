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

module Costs
  module Patches::MembersPatch
    def self.mixin!
      ::Members::TableComponent.add_column :current_rate
      ::Members::TableComponent.options :current_user # adds current_user option

      ::MembersController.prepend TableOptions
      ::Members::TableComponent.prepend TableComponent
      ::Members::RowComponent.prepend RowComponent
    end

    module TableOptions
      def members_table_options(_roles)
        super.merge current_user:
      end
    end

    module TableComponent
      def sort_collection(query, sort_clause, sort_columns)
        q = super(query, sort_clause.gsub("current_rate", "COALESCE(rate, 0.0)"), sort_columns)

        if sort_columns.include? :current_rate
          join_rate q
        else
          q
        end
      end

      ##
      # Joins user's rates so the results can be sorted by them.
      # Each member is paired by one rate row of either (if present, in this order):
      #
      #   1) a user's rate in the given project
      #   2) a user's rate in one of the given project's parents
      #   3) a user's default rate
      #
      # This mirrors the behaviour as implemented in `HourlyRate#at_date_for_user_in_project`.
      def join_rate(query)
        query
          .joins(
            "
              LEFT JOIN rates ON rates.id = (
                SELECT rate_union.id
                FROM (
                  #{project_rates} UNION #{parent_project_rates} UNION #{default_rates}
                ) AS rate_union
                LEFT JOIN projects ON rate_union.project_id = projects.id
                WHERE rate_union.user_id = members.user_id AND rate_union.rate IS NOT NULL
                GROUP BY project_id, valid_from, projects.lft, rate_union.id
                ORDER BY
                  CASE
                    WHEN project_id = #{project.id} THEN 0
                    WHEN project_Id IS NOT NULL then 1
                    ELSE 2
                  END ASC, projects.lft DESC, valid_from DESC
                LIMIT 1
              )
            "
          )
      end

      def project_rates
        "
          SELECT * FROM rates
          WHERE project_id = #{project.id} AND valid_from <= '#{rate_valid_from}'
        "
      end

      def parent_project_rates
        "
          SELECT * FROM (
            SELECT rates.* FROM rates
            WHERE project_id IN (#{parent_project_ids}) AND valid_from <= '#{rate_valid_from}'
          ) AS parent_project_rates
        "
      end

      def default_rates
        "
          SELECT * FROM rates
          WHERE type = 'DefaultHourlyRate' AND valid_from <= '#{rate_valid_from}'
        "
      end

      def rate_valid_from
        Date.today.strftime("%Y-%m-%d")
      end

      def parent_project_ids
        ids = project.ancestors.pluck(:id).presence || [0]
        ids.join(", ")
      end

      def project
        options[:project]
      end

      def columns
        if costs_enabled?
          super # all columns including :current_rate as defined in `Members.mixin!`
        else
          super - [:current_rate]
        end
      end

      def costs_enabled?
        if @costs_enabled.nil?
          @costs_enabled = project.present? && project.module_enabled?(:costs)
        end

        @costs_enabled
      end
    end

    module RowComponent
      include ActionView::Helpers::NumberHelper # for #number_to_currency

      ##
      # Getter for row's current_rate column
      # the result of which is rendered in the table.
      def current_rate
        if show_rate?
          link_to(
            number_to_currency(rate),
            controller: "/hourly_rates",
            action: rate_action,
            id: member.principal,
            project_id: project
          )
        end
      end

      delegate :project, to: :table

      def column_css_class(name)
        if name == :current_rate
          "currency"
        else
          super
        end
      end

      def rate
        member.principal.current_rate(project).try(:rate) || 0.0
      end

      def rate_action
        if allow_edit?
          "edit"
        else
          "show"
        end
      end

      def show_rate?
        costs_enabled? && user? && allow_view?
      end

      def costs_enabled?
        project.present? && project.module_enabled?(:costs)
      end

      def allow_view?
        table.current_user.allowed_in_project?(:view_hourly_rates, project)
      end

      def allow_edit?
        table.current_user.allowed_in_project?(:edit_hourly_rates, project)
      end
    end
  end
end
