#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
  module V1

    class TimelogController < TimelogController

      include ::Api::V1::ApiController

      def index
        sort_init 'spent_on', 'desc'
        sort_update 'spent_on' => 'spent_on',
                    'user' => 'user_id',
                    'activity' => 'activity_id',
                    'project' => "#{Project.table_name}.name",
                    'issue' => 'issue_id',
                    'hours' => 'hours'

        cond = ARCondition.new
        if @issue
          cond << "#{WorkPackage.table_name}.root_id = #{@issue.root_id} AND #{WorkPackage.table_name}.lft >= #{@issue.lft} AND #{WorkPackage.table_name}.rgt <= #{@issue.rgt}"
        elsif @project
          cond << @project.project_condition(Setting.display_subprojects_work_packages?)
        end

        retrieve_date_range
        cond << ['spent_on BETWEEN ? AND ?', @from, @to]

        respond_to do |format|
          format.api  {
            @entry_count = TimeEntry.visible.count(:include => [:project, :work_package], :conditions => cond.conditions)
            @entries = TimeEntry.visible.includes(:project, :activity, :user, {:work_package => :type})
                                        .where(cond.conditions)
                                        .order(sort_clause)
                                        .page(page_param)
                                        .per_page(per_page_param)
          }
        end
      end

      def show
        respond_to do |format|
          format.api
        end
      end

      def create
        @time_entry ||= TimeEntry.new(:project => @project, :work_package => @issue, :user => User.current, :spent_on => User.current.today)
        @time_entry.safe_attributes = params[:time_entry]

        call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

        if @time_entry.save
          respond_to do |format|
            format.api  { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
          end
        else
          respond_to do |format|
            format.api  { render_validation_errors(@time_entry) }
          end
        end
      end

      def update
        @time_entry.safe_attributes = params[:time_entry]

        call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

        if @time_entry.save
          respond_to do |format|
            format.api  { head :ok }
          end
        else
          respond_to do |format|
            format.api  { render_validation_errors(@time_entry) }
          end
        end
      end

      def destroy
        if @time_entry.destroy && @time_entry.destroyed?
          respond_to do |format|
            format.api { head :ok }
          end
        else
          respond_to do |format|
            format.api { render_validation_errors(@time_entry) }
          end
        end
      rescue ::ActionController::RedirectBackError
        redirect_to :action => 'index', :project_id => @time_entry.project
      end

    end
  end
end
