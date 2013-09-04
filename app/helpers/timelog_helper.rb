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

module TimelogHelper
  include ApplicationHelper

  def render_timelog_breadcrumb
    links = []
    links << link_to(l(:label_project_all), {:project_id => nil, :work_package_id => nil})
    links << link_to(h(@project), {:project_id => @project, :work_package_id => nil}) if @project
    if @issue
      if @issue.visible?
        links << link_to_work_package(@issue, :subject => false)
      else
        links << "##{@issue.id}".html_safe
      end
    end
    breadcrumb links
  end

  # Returns a collection of activities for a select field.  time_entry
  # is optional and will be used to check if the selected TimeEntryActivity
  # is active.
  def activity_collection_for_select_options(time_entry=nil, project=nil)
    project ||= @project
    if project.nil?
      activities = TimeEntryActivity.shared.active
    else
      activities = project.activities
    end

    collection = []
    if time_entry && time_entry.activity && !time_entry.activity.active?
      collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ]
    else
      collection << [ "--- #{l(:actionview_instancetag_blank_option)} ---", '' ] unless activities.detect(&:is_default)
    end
    activities.each { |a| collection << [a.name, a.id] }
    collection
  end

  def select_hours(data, criteria, value)
  	if value.to_s.empty?
  		data.select {|row| row[criteria].blank? }
    else
    	data.select {|row| row[criteria].to_s == value.to_s}
    end
  end

  def sum_hours(data)
    sum = 0
    data.each do |row|
      sum += row['hours'].to_f
    end
    sum
  end

  def options_for_period_select(value)
    options_for_select([[l(:label_all_time), 'all'],
                        [l(:label_today), 'today'],
                        [l(:label_yesterday), 'yesterday'],
                        [l(:label_this_week), 'current_week'],
                        [l(:label_last_week), 'last_week'],
                        [l(:label_last_n_days, 7), '7_days'],
                        [l(:label_this_month), 'current_month'],
                        [l(:label_last_month), 'last_month'],
                        [l(:label_last_n_days, 30), '30_days'],
                        [l(:label_this_year), 'current_year']],
                        value)
  end

  def entries_to_csv(entries)
    decimal_separator = l(:general_csv_decimal_separator)
    custom_fields = TimeEntryCustomField.find(:all)
    export = CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [TimeEntry.human_attribute_name(:spent_on),
                 TimeEntry.human_attribute_name(:user),
                 TimeEntry.human_attribute_name(:activity),
                 TimeEntry.human_attribute_name(:project),
                 TimeEntry.human_attribute_name(:issue),
                 TimeEntry.human_attribute_name(:type),
                 TimeEntry.human_attribute_name(:subject),
                 TimeEntry.human_attribute_name(:hours),
                 TimeEntry.human_attribute_name(:comments)
                 ]
      # Export custom fields
      headers += custom_fields.collect(&:name)

      csv << headers.collect {|c| begin; c.to_s.encode(l(:general_csv_encoding), 'UTF-8'); rescue; c.to_s; end }
      # csv lines
      entries.each do |entry|
        fields = [format_date(entry.spent_on),
                  entry.user,
                  entry.activity,
                  entry.project,
                  (entry.work_package ? entry.work_package.id : nil),
                  (entry.work_package ? entry.work_package.type : nil),
                  (entry.work_package ? entry.work_package.subject : nil),
                  entry.hours.to_s.gsub('.', decimal_separator),
                  entry.comments
                  ]
        fields += custom_fields.collect {|f| show_value(entry.custom_value_for(f)) }

        csv << fields.collect {|c| begin; c.to_s.encode(l(:general_csv_encoding), 'UTF-8'); rescue; c.to_s; end }
      end
    end
    export
  end

  def format_criteria_value(criteria, value)
    if value.blank?
      l(:label_none)
    elsif k = @available_criterias[criteria][:klass]
      obj = k.find_by_id(value.to_i)
      if obj.is_a?(Issue)
        obj.visible? ? h("#{obj.type} ##{obj.id}: #{obj.subject}") : h("##{obj.id}")
      else
        obj
      end
    else
      format_value(value, @available_criterias[criteria][:format])
    end
  end

  def report_to_csv(criterias, periods, hours)
    export = CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # Column headers
      headers = criterias.collect do |criteria|
        label = @available_criterias[criteria][:label]
        label.is_a?(Symbol) ? l(label) : label
      end
      headers += periods
      headers << l(:label_total)
      csv << headers.collect {|c| to_utf8_for_timelogs(c) }
      # Content
      report_criteria_to_csv(csv, criterias, periods, hours)
      # Total row
      row = [ l(:label_total) ] + [''] * (criterias.size - 1)
      total = 0
      periods.each do |period|
        sum = sum_hours(select_hours(hours, @columns, period.to_s))
        total += sum
        row << (sum > 0 ? "%.2f" % sum : '')
      end
      row << "%.2f" %total
      csv << row
    end
    export
  end

  def report_criteria_to_csv(csv, criterias, periods, hours, level=0)
    hours.collect {|h| h[criterias[level]].to_s}.uniq.each do |value|
      hours_for_value = select_hours(hours, criterias[level], value)
      next if hours_for_value.empty?
      row = [''] * level
      row << to_utf8_for_timelogs(format_criteria_value(criterias[level], value))
      row += [''] * (criterias.length - level - 1)
      total = 0
      periods.each do |period|
        sum = sum_hours(select_hours(hours_for_value, @columns, period.to_s))
        total += sum
        row << (sum > 0 ? "%.2f" % sum : '')
      end
      row << "%.2f" %total
      csv << row

      if criterias.length > level + 1
        report_criteria_to_csv(csv, criterias, periods, hours_for_value, level + 1)
      end
    end
  end

  def to_utf8_for_timelogs(s)
    begin; s.to_s.encode(l(:general_csv_encoding), 'UTF-8'); rescue; s.to_s; end
  end

  def polymorphic_time_entries_path(object)
    polymorphic_path([object, :time_entries])
  end

  def polymorphic_new_time_entry_path(object)
    polymorphic_path([:new, object, :time_entry,])
  end

  def polymorphic_time_entries_report_path(object)
    polymorphic_path([object, :time_entries, :report])
  end
end
