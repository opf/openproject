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
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper
  helper :issues
  
  def report
    @available_criterias = { 'version' => {:sql => "#{Issue.table_name}.fixed_version_id",
                                          :values => @project.versions,
                                          :label => :label_version},
                             'category' => {:sql => "#{Issue.table_name}.category_id",
                                            :values => @project.issue_categories,
                                            :label => :field_category},
                             'member' => {:sql => "#{TimeEntry.table_name}.user_id",
                                         :values => @project.users,
                                         :label => :label_member},
                             'tracker' => {:sql => "#{Issue.table_name}.tracker_id",
                                          :values => Tracker.find(:all),
                                          :label => :label_tracker},
                             'activity' => {:sql => "#{TimeEntry.table_name}.activity_id",
                                           :values => Enumeration::get_values('ACTI'),
                                           :label => :label_activity}
                           }
    
    @criterias = params[:criterias] || []
    @criterias = @criterias.select{|criteria| @available_criterias.has_key? criteria}
    @criterias.uniq!
    
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
      sql << " FROM #{TimeEntry.table_name} LEFT JOIN #{Issue.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id"
      sql << " WHERE #{TimeEntry.table_name}.project_id = %s" % @project.id
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
    
    @entries = (@issue ? @issue : @project).time_entries.find(:all, :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}], :order => sort_clause)

    @total_hours = @entries.inject(0) { |sum,entry| sum + entry.hours }
    @owner_id = User.current.id
    
    send_csv and return if 'csv' == params[:export]    
    render :action => 'details', :layout => false if request.xhr?
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
  
  def send_csv
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [l(:field_spent_on),
                 l(:field_user),
                 l(:field_activity),
                 l(:field_issue),
                 l(:field_hours),
                 l(:field_comments)
                 ]
      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      @entries.each do |entry|
        fields = [l_date(entry.spent_on),
                  entry.user.name,
                  entry.activity.name,
                  (entry.issue ? entry.issue.id : nil),
                  entry.hours,
                  entry.comments
                  ]
        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    send_data(export.read, :type => 'text/csv; header=present', :filename => 'export.csv')
  end
end
