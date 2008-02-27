# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class TimelogController < ApplicationController
  layout 'base'
  menu_item :issues
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper
  helper :issues
  include TimelogHelper
  
  def report
    @available_criterias = { 'project' => {:sql => "#{TimeEntry.table_name}.project_id",
                                          :klass => Project,
                                          :label => :label_project},
                             'version' => {:sql => "#{Issue.table_name}.fixed_version_id",
                                          :klass => Version,
                                          :label => :label_version},
                             'category' => {:sql => "#{Issue.table_name}.category_id",
                                            :klass => IssueCategory,
                                            :label => :field_category},
                             'member' => {:sql => "#{TimeEntry.table_name}.user_id",
                                         :klass => User,
                                         :label => :label_member},
                             'tracker' => {:sql => "#{Issue.table_name}.tracker_id",
                                          :klass => Tracker,
                                          :label => :label_tracker},
                             'activity' => {:sql => "#{TimeEntry.table_name}.activity_id",
                                           :klass => Enumeration,
                                           :label => :label_activity}
                           }
    
    @criterias = params[:criterias] || []
    @criterias = @criterias.select{|criteria| @available_criterias.has_key? criteria}
    @criterias.uniq!
    @criterias = @criterias[0,3]
    
    @columns = (params[:period] && %w(year month week).include?(params[:period])) ? params[:period] : 'month'
    
    if params[:date_from]
      begin; @date_from = params[:date_from].to_date; rescue; end
    end
    if params[:date_to]
      begin; @date_to = params[:date_to].to_date; rescue; end
    end
    @date_from ||= Date.civil(Date.today.year, 1, 1)
    @date_to ||= (Date.civil(Date.today.year, Date.today.month, 1) >> 1) - 1
    
    unless @criterias.empty?
      sql_select = @criterias.collect{|criteria| @available_criterias[criteria][:sql] + " AS " + criteria}.join(', ')
      sql_group_by = @criterias.collect{|criteria| @available_criterias[criteria][:sql]}.join(', ')
      
      sql = "SELECT #{sql_select}, tyear, tmonth, tweek, SUM(hours) AS hours"
      sql << " FROM #{TimeEntry.table_name}"
      sql << " LEFT JOIN #{Issue.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id"
      sql << " LEFT JOIN #{Project.table_name} ON #{TimeEntry.table_name}.project_id = #{Project.table_name}.id"
      sql << " WHERE (#{Project.table_name}.id = %s OR #{Project.table_name}.parent_id = %s)" % [@project.id, @project.id]
      sql << " AND (%s)" % Project.allowed_to_condition(User.current, :view_time_entries)
      sql << " AND spent_on BETWEEN '%s' AND '%s'" % [ActiveRecord::Base.connection.quoted_date(@date_from.to_time), ActiveRecord::Base.connection.quoted_date(@date_to.to_time)]
      sql << " GROUP BY #{sql_group_by}, tyear, tmonth, tweek"
      
      @hours = ActiveRecord::Base.connection.select_all(sql)
      
      @hours.each do |row|
        case @columns
        when 'year'
          row['year'] = row['tyear']
        when 'month'
          row['month'] = "#{row['tyear']}-#{row['tmonth']}"
        when 'week'
          row['week'] = "#{row['tyear']}-#{row['tweek']}"
        end
      end
      
      @total_hours = @hours.inject(0) {|s,k| s = s + k['hours'].to_f}
    end
       
    @periods = []
    date_from = @date_from
    # 100 columns max
    while date_from < @date_to && @periods.length < 100
      case @columns
      when 'year'
        @periods << "#{date_from.year}"
        date_from = date_from >> 12
      when 'month'
        @periods << "#{date_from.year}-#{date_from.month}"
        date_from = date_from >> 1
      when 'week'
        @periods << "#{date_from.year}-#{date_from.cweek}"
        date_from = date_from + 7
      end
    end
    
    render :layout => false if request.xhr?
  end
  
  def details
    sort_init 'spent_on', 'desc'
    sort_update

    @free_period = false
    @from, @to = nil, nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1)%7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1)%7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
    else
      # default
    end
    
    @from, @to = @to, @from if @from && @to && @from > @to
    
    cond = ARCondition.new
    cond << (@issue.nil? ? ["(#{Project.table_name}.id = ? OR #{Project.table_name}.parent_id = ?)", @project.id, @project.id] :
                           ["#{TimeEntry.table_name}.issue_id = ?", @issue.id])
    
    if @from
      if @to
        cond << ['spent_on BETWEEN ? AND ?', @from, @to]
      else
        cond << ['spent_on >= ?', @from]
      end
    elsif @to
      cond << ['spent_on <= ?', @to]
    end

    TimeEntry.visible_by(User.current) do
      respond_to do |format|
        format.html {
          # Paginate results
          @entry_count = TimeEntry.count(:include => :project, :conditions => cond.conditions)
          @entry_pages = Paginator.new self, @entry_count, per_page_option, params['page']
          @entries = TimeEntry.find(:all, 
                                    :include => [:project, :activity, :user, {:issue => :tracker}],
                                    :conditions => cond.conditions,
                                    :order => sort_clause,
                                    :limit  =>  @entry_pages.items_per_page,
                                    :offset =>  @entry_pages.current.offset)
          @total_hours = TimeEntry.sum(:hours, :include => :project, :conditions => cond.conditions).to_f
          render :layout => !request.xhr?
        }
        format.csv {
          # Export all entries
          @entries = TimeEntry.find(:all, 
                                    :include => [:project, :activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                    :conditions => cond.conditions,
                                    :order => sort_clause)
          send_data(entries_to_csv(@entries).read, :type => 'text/csv; header=present', :filename => 'timelog.csv')
        }
      end
    end
  end
  
  def edit
    render_404 and return if @time_entry && @time_entry.user != User.current
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => Date.today)
    @time_entry.attributes = params[:time_entry]
    if request.post? and @time_entry.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'details', :project_id => @time_entry.project, :issue_id => @time_entry.issue
      return
    end    
    @activities = Enumeration::get_values('ACTI')
  end

private
  def find_project
    if params[:id]
      @time_entry = TimeEntry.find(params[:id])
      @project = @time_entry.project
    elsif params[:issue_id]
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif params[:project_id]
      @project = Project.find(params[:project_id])
    else
      render_404
      return false
    end
  end
end
