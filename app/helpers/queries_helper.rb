#-- encoding: UTF-8
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

module QueriesHelper

  def operators_for_select(filter_type)
    Queries::Filter.operators_by_filter_type[filter_type].collect {|o| [l(Queries::Filter.operators[o]), o]}
  end

  def column_locale(column)
    (column.is_a? QueryCustomFieldColumn) ? column.custom_field.name_locale : nil
  end

  def column_header(column)
    column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
                                                        :default_order => column.default_order,
                                                        :lang => column_locale(column))
                    : content_tag('th', h(column.caption), :lang => column_locale(column))
  end

  def column_content(column, issue)
    value = column.value(issue)

    case value.class.name
    when 'String'
      if column.name == :subject
        link_to(h(value), work_package_path(issue))
      else
        h(value)
      end
    when 'Time'
      format_time(value)
    when 'Date'
      format_date(value)
    when 'Fixnum', 'Float'
      if column.name == :done_ratio
        progress_bar(value, :width => '80px')
      else
        h(value.to_s)
      end
    when 'User'
      link_to_user value
    when 'Project'
      link_to_project value
    when 'Version'
      link_to(h(value), :controller => '/versions', :action => 'show', :id => value)
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    when 'Issue', 'PlanningElement'
      link_to_work_package(value, :subject => false)
    else
      h(value)
    end
  end

  def add_filter_from_params
    @query.filters = []
    @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
  end

  # Retrieve query from session or build a new query
  def retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(params[:query_id], :conditions => cond)
      @query.project = @project
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    else
      if api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        @query = Query.new({name: "_"}, initialize_with_default_filter: true)
        @query.project = @project
        if params[:fields] || params[:f]
          add_filter_from_params
        else
          @query.available_work_package_filters.keys.each do |field|
            @query.add_short_filter(field, params[field]) if params[field]
          end
        end
        @query.group_by = params[:group_by]
        @query.display_sums = params[:display_sums].present?
        @query.column_names = params[:c] || (params[:query] && params[:query][:column_names])
        session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :display_sums => @query.display_sums, :column_names => @query.column_names}
      else
        @query = Query.find_by_id(session[:query][:id]) if session[:query][:id]
        @query ||= Query.new(:name => "_", :project => @project, :filters => session[:query][:filters], :group_by => session[:query][:group_by], :display_sums => session[:query][:display_sums], :column_names => session[:query][:column_names])
        @query.project = @project
      end
    end

    @query
  end
end
