#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_dependency 'timelog_controller'

module OpenProject::Reporting::Patches
  module TimelogControllerPatch
    def self.included(base) # :nodoc:
      base.prepend InstanceMethods
    end

    module InstanceMethods
      ##
      # @Override
      # This is for cost reporting
      def redirect_to(*args, &block)
        if args.first == :back and args.size == 1 and request.referer =~ /cost_reports/
          super(controller: '/cost_reports', action: :index)
        else
          super(*args, &block)
        end
      end

      def index
        # we handle single project reporting currently
        if @project.nil? || !@project.module_enabled?(:reporting_module)
          return super
        end
        filters = {operators: {}, values: {}}

        if @issue
          if @issue.respond_to?("lft")
            work_package_ids = @issue.self_and_descendants.pluck(:id)
          else
            work_package_ids = [@issue.id.to_s]
          end

          filters[:operators][:work_package_id] = "="
          filters[:values][:work_package_id] = [work_package_ids]
        end

        filters[:operators][:project_id] = "="
        filters[:values][:project_id] = [@project.id.to_s]

        respond_to do |format|
          format.html {
            session[::CostQuery.name.underscore.to_sym] = { filters: filters, groups: {rows: [], columns: []} }

            redirect_to controller: "/cost_reports", action: "index", project_id: @project, unit: -1
          }
          format.all {
            super
          }
        end
      end

      def find_optional_project
        if !params[:work_package_id].blank?
          @issue = WorkPackage.find(params[:work_package_id])
          @project = @issue.project
        elsif !params[:project_id].blank?
          @project = Project.find(params[:project_id])
        end
        deny_access unless User.current.allowed_to?(:view_time_entries, @project, global: true) ||
                           User.current.allowed_to?(:view_own_time_entries, @project, global: true)
      end
    end
  end
end
