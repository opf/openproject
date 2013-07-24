#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Issues::CalendarsController < ApplicationController
  menu_item :calendar
  before_filter :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  include QueriesHelper
  include SortHelper

  def index
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query
    @query.group_by = nil
    if @query.valid?
      events = []
      events += @query.issues(:include => [:type, :assigned_to, :priority],
                              :conditions => ["((#{WorkPackage.table_name}.start_date BETWEEN ? AND ?) OR (#{WorkPackage.table_name}.due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                              )
      events += @query.versions(:conditions => ["#{Version.table_name}.effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])

      @calendar.events = events
    end

    render :layout => !request.xhr?
  end

private

  def default_breadcrumb
    l(:label_calendar)
  end
end
