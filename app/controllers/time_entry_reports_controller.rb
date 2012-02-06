#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class TimeEntryReportsController < ApplicationController
  menu_item :issues
  before_filter :find_optional_project
  before_filter :load_available_criterias

  include SortHelper
  include TimelogHelper
  include CustomFieldsHelper

  def report
    @criterias = params[:criterias] || []
    @criterias = @criterias.select{|criteria| @available_criterias.has_key? criteria}
    @criterias.uniq!
    @criterias = @criterias[0,3]

    @columns = (params[:columns] && %w(year month week day).include?(params[:columns])) ? params[:columns] : 'month'

    retrieve_date_range

    unless @criterias.empty?
      sql_select = @criterias.collect{|criteria| @available_criterias[criteria][:sql] + " AS " + criteria}.join(', ')
      sql_group_by = @criterias.collect{|criteria| @available_criterias[criteria][:sql]}.join(', ')
      sql_condition = ''

      if @project.nil?
        sql_condition = Project.allowed_to_condition(User.current, :view_time_entries)
      elsif @issue.nil?
        sql_condition = @project.project_condition(Setting.display_subprojects_issues?)
      else
        sql_condition = "#{Issue.table_name}.root_id = #{@issue.root_id} AND #{Issue.table_name}.lft >= #{@issue.lft} AND #{Issue.table_name}.rgt <= #{@issue.rgt}"
      end

      sql = "SELECT #{sql_select}, tyear, tmonth, tweek, spent_on, SUM(hours) AS hours"
      sql << " FROM #{TimeEntry.table_name}"
      sql << time_report_joins
      sql << " WHERE"
      sql << " (%s) AND" % sql_condition
      sql << " (spent_on BETWEEN '%s' AND '%s')" % [ActiveRecord::Base.connection.quoted_date(@from), ActiveRecord::Base.connection.quoted_date(@to)]
      sql << " GROUP BY #{sql_group_by}, tyear, tmonth, tweek, spent_on"

      @hours = ActiveRecord::Base.connection.select_all(sql)

      @hours.each do |row|
        case @columns
        when 'year'
          row['year'] = row['tyear']
        when 'month'
          row['month'] = "#{row['tyear']}-#{row['tmonth']}"
        when 'week'
          row['week'] = "#{row['tyear']}-#{row['tweek']}"
        when 'day'
          row['day'] = "#{row['spent_on']}"
        end
      end

      @total_hours = @hours.inject(0) {|s,k| s = s + k['hours'].to_f}

      @periods = []
      # Date#at_beginning_of_ not supported in Rails 1.2.x
      date_from = @from.to_time
      while date_from <= @to.to_time
        case @columns
        when 'year'
          @periods << "#{date_from.year}"
          date_from = (date_from + 1.year).at_beginning_of_year
        when 'month'
          @periods << "#{date_from.year}-#{date_from.month}"
          date_from = (date_from + 1.month).at_beginning_of_month
        when 'week'
          @periods << "#{date_from.year}-#{date_from.to_date.cweek}"
          date_from = (date_from + 7.day).at_beginning_of_week
        when 'day'
          @periods << "#{date_from.to_date}"
          date_from = date_from + 1.day
        end
      end
    end

    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.csv  { send_data(report_to_csv(@criterias, @periods, @hours), :type => 'text/csv; header=present', :filename => 'timelog.csv') }
    end
  end

  private

  # TODO: duplicated in TimelogController
  def find_optional_project
    if !params[:issue_id].blank?
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
    end
    deny_access unless User.current.allowed_to?(:view_time_entries, @project, :global => true)
  end

  # Retrieves the date range based on predefined ranges or specific from/to param dates
  # TODO: duplicated in TimelogController
  def retrieve_date_range
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
    @from ||= (TimeEntry.earilest_date_for_project(@project) || Date.today)
    @to   ||= (TimeEntry.latest_date_for_project(@project) || Date.today)
  end

  def load_available_criterias
    @available_criterias = { 'project' => {:sql => "#{TimeEntry.table_name}.project_id",
                                          :klass => Project,
                                          :label => :label_project},
                             'status' => {:sql => "#{Issue.table_name}.status_id",
                                          :klass => IssueStatus,
                                          :label => :field_status},
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
                                           :klass => TimeEntryActivity,
                                           :label => :label_activity},
                             'issue' => {:sql => "#{TimeEntry.table_name}.issue_id",
                                         :klass => Issue,
                                         :label => :label_issue}
                           }

    # Add list and boolean custom fields as available criterias
    custom_fields = (@project.nil? ? IssueCustomField.for_all : @project.all_issue_custom_fields)
    custom_fields.select {|cf| %w(list bool).include? cf.field_format }.each do |cf|
      @available_criterias["cf_#{cf.id}"] = {:sql => "(SELECT c.value FROM #{CustomValue.table_name} c WHERE c.custom_field_id = #{cf.id} AND c.customized_type = 'Issue' AND c.customized_id = #{Issue.table_name}.id)",
                                             :format => cf.field_format,
                                             :label => cf.name}
    end if @project

    # Add list and boolean time entry custom fields
    TimeEntryCustomField.find(:all).select {|cf| %w(list bool).include? cf.field_format }.each do |cf|
      @available_criterias["cf_#{cf.id}"] = {:sql => "(SELECT c.value FROM #{CustomValue.table_name} c WHERE c.custom_field_id = #{cf.id} AND c.customized_type = 'TimeEntry' AND c.customized_id = #{TimeEntry.table_name}.id)",
                                             :format => cf.field_format,
                                             :label => cf.name}
    end

    # Add list and boolean time entry activity custom fields
    TimeEntryActivityCustomField.find(:all).select {|cf| %w(list bool).include? cf.field_format }.each do |cf|
      @available_criterias["cf_#{cf.id}"] = {:sql => "(SELECT c.value FROM #{CustomValue.table_name} c WHERE c.custom_field_id = #{cf.id} AND c.customized_type = 'Enumeration' AND c.customized_id = #{TimeEntry.table_name}.activity_id)",
                                             :format => cf.field_format,
                                             :label => cf.name}
    end

    call_hook(:controller_timelog_available_criterias, { :available_criterias => @available_criterias, :project => @project })
    @available_criterias
  end

  def time_report_joins
    sql = ''
    sql << " LEFT JOIN #{Issue.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id"
    sql << " LEFT JOIN #{Project.table_name} ON #{TimeEntry.table_name}.project_id = #{Project.table_name}.id"
    # TODO: rename hook
    call_hook(:controller_timelog_time_report_joins, {:sql => sql} )
    sql
  end

end
