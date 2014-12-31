#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api
  module V2
    class ReportingsController < ReportingsController
      include ::Api::V2::ApiController

      def self.accept_key_auth_actions
        super + ['available_projects']
      end

      def available_projects
        available_projects = @project.reporting_to_project_candidates
        respond_to do |format|
          format.api {
            @elements = Project.project_level_list(Project.visible)
            @disabled = Project.visible - available_projects
          }
        end
      end

      def index
        condition_params = []
        temp_condition = ''
        condition = ''

        if params[:project_types].present?
          project_types = params[:project_types].split(/,/).map(&:to_i)
          temp_condition += "#{Project.quoted_table_name}.project_type_id IN (?)"
          condition_params << project_types
          if project_types.include?(-1)
            temp_condition += " OR #{Project.quoted_table_name}.project_type_id IS NULL"
            temp_condition = "(#{temp_condition})"
          end
        end

        condition += temp_condition
        temp_condition = ''

        if params[:project_statuses].present?
          condition += ' AND ' unless condition.empty?

          project_statuses = params[:project_statuses].split(/,/).map(&:to_i)
          temp_condition += "#{Reporting.quoted_table_name}.reported_project_status_id IN (?)"
          condition_params << project_statuses
          if project_statuses.include?(-1)
            temp_condition += " OR #{Reporting.quoted_table_name}.reported_project_status_id IS NULL"
            temp_condition = "(#{temp_condition})"
          end
        end

        condition += temp_condition
        temp_condition = ''

        if params[:project_responsibles].present?
          condition += ' AND ' unless condition.empty?

          project_responsibles = params[:project_responsibles].split(/,/).map(&:to_i)
          temp_condition += "#{Project.quoted_table_name}.responsible_id IN (?)"
          condition_params << project_responsibles
          if project_responsibles.include?(-1)
            temp_condition += " OR #{Project.quoted_table_name}.responsible_id  IS NULL"
            temp_condition = "(#{temp_condition})"
          end
        end

        condition += temp_condition
        temp_condition = ''

        if params[:project_parents].present?
          condition += ' AND ' unless condition.empty?

          project_parents = params[:project_parents].split(/,/).map(&:to_i)
          nested_set_selection = Project.find(project_parents).map { |p| p.lft..p.rgt }.inject([]) { |r, e| e.each { |i| r << i }; r }

          temp_condition += "#{Project.quoted_table_name}.lft IN (?)"
          condition_params << nested_set_selection
        end

        condition += temp_condition
        temp_condition = ''

        if params[:grouping_one].present? && condition.present?
          condition += ' OR '

          grouping = params[:grouping_one].split(/,/).map(&:to_i)
          temp_condition += "#{Project.quoted_table_name}.id IN (?)"
          condition_params << grouping
        end

        condition += temp_condition
        conditions = [condition] + condition_params unless condition.empty?

        case params[:only]
        when 'via_source'
          @reportings = @project.reportings_via_source.find(:all,
                                                            include: :project,
                                                            conditions: conditions
            )
        when 'via_target'
          @reportings = @project.reportings_via_target.find(:all,
                                                            include: :project,
                                                            conditions: conditions
            )
        else
          @reportings = @project.reportings.all
        end

        # get all reportings for which projects have ancestors.
        nested_sets_for_parents = (@reportings.inject([]) { |r, e| r << e.reporting_to_project; r << e.project }).uniq.map { |p| [p.lft, p.rgt] }

        condition_params = []
        temp_condition = ''
        condition = ''

        nested_sets_for_parents.each do |set|
          condition += ' OR ' unless condition.empty?
          condition += "#{Project.quoted_table_name}.lft < ? AND #{Project.quoted_table_name}.rgt > ?"
          condition_params << set[0]
          condition_params << set[1]
        end

        conditions = [condition] + condition_params unless condition.empty?

        case params[:only]
        when 'via_source'
          @ancestor_reportings = @project.reportings_via_source.find(:all,
                                                                     include: :project,
                                                                     conditions: conditions
            )
        when 'via_target'
          @ancestor_reportings = @project.reportings_via_target.find(:all,
                                                                     include: :project,
                                                                     conditions: conditions
            )
        else
          @ancestor_reportings = @project.reportings.all
        end

        @reportings = (@reportings + @ancestor_reportings).uniq

        respond_to do |format|
          format.api do
            @reportings.select(&:visible?)
          end
        end
      end

      def show
        @reporting = @project.reportings_via_source.find(params[:id])
        check_visibility

        respond_to do |format|
          format.api
        end
      end
    end
  end
end
