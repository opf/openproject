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

module IssuesHelper
  include ApplicationHelper

  def issue_list(issues, &block)
    ancestors = []
    issues.each do |issue|
      while (ancestors.any? && !issue.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield issue, ancestors.size
      ancestors << issue unless issue.leaf?
    end
  end

  # Renders a HTML/CSS tooltip
  #
  # To use, a trigger div is needed.  This is a div with the class of "tooltip"
  # that contains this method wrapped in a span with the class of "tip"
  #
  #    <div class="tooltip"><%= link_to_issue(issue) %>
  #      <span class="tip"><%= render_issue_tooltip(issue) %></span>
  #    </div>
  #
  def render_issue_tooltip(issue)
    @cached_label_status ||= l(:field_status)
    @cached_label_start_date ||= l(:field_start_date)
    @cached_label_due_date ||= l(:field_due_date)
    @cached_label_assigned_to ||= l(:field_assigned_to)
    @cached_label_priority ||= l(:field_priority)
    @cached_label_project ||= l(:field_project)

    link_to_issue(issue) + "<br /><br />" +
      "<strong>#{@cached_label_project}</strong>: #{link_to_project(issue.project)}<br />" +
      "<strong>#{@cached_label_status}</strong>: #{h(issue.status.name)}<br />" +
      "<strong>#{@cached_label_start_date}</strong>: #{format_date(issue.start_date)}<br />" +
      "<strong>#{@cached_label_due_date}</strong>: #{format_date(issue.due_date)}<br />" +
      "<strong>#{@cached_label_assigned_to}</strong>: #{h(issue.assigned_to)}<br />" +
      "<strong>#{@cached_label_priority}</strong>: #{h(issue.priority.name)}"
  end

  # TODO: deprecate and/or remove
  def render_issue_subject_with_tree(issue)
    s = ''
    ancestors = issue.root? ? [] : issue.ancestors.all
    ancestors.each do |ancestor|
      s << '<div>' + content_tag('h2', link_to_issue(ancestor))
    end
    s << '<div class="subject">' + content_tag('h2', h(issue.subject))
    s << '</div>' * (ancestors.size + 1)
    s
  end

  def render_descendants_tree(issue)
    s = '<form><table class="list issues">'
    issue_list(issue.descendants.sort_by(&:lft)) do |child, level|
      s << content_tag('tr',
             content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
             content_tag('td', link_to_issue(child, :truncate => 60), :class => 'subject') +
             content_tag('td', h(child.status)) +
             content_tag('td', link_to_user(child.assigned_to)) +
             content_tag('td', progress_bar(child.done_ratio, :width => '80px')),
             :class => "issue issue-#{child.id} hascontextmenu #{level > 0 ? "idnt idnt-#{level}" : nil}")
    end
    s << '</form></table>'
    s
  end

  def render_custom_fields_rows(issue)
    return if issue.custom_field_values.empty?
    ordered_values = []
    half = (issue.custom_field_values.size / 2.0).ceil
    half.times do |i|
      ordered_values << issue.custom_field_values[i]
      ordered_values << issue.custom_field_values[i + half]
    end
    s = "<tr>\n"
    n = 0
    ordered_values.compact.each do |value|
      s << "</tr>\n<tr>\n" if n > 0 && (n % 2) == 0
      s << "\t<th>#{ h(value.custom_field.name) }:</th><td>#{ simple_format_without_paragraph(h(show_value(value))) }</td>\n"
      n += 1
    end
    s << "</tr>\n"
    s
  end

  def sidebar_queries
    unless @sidebar_queries
      # User can see public queries and his own queries
      visible = ARCondition.new(["is_public = ? OR user_id = ?", true, (User.current.logged? ? User.current.id : 0)])
      # Project specific queries and global queries
      visible << (@project.nil? ? ["project_id IS NULL"] : ["project_id IS NULL OR project_id = ?", @project.id])
      @sidebar_queries = Query.find(:all,
                                    :select => 'id, name, is_public',
                                    :order => "name ASC",
                                    :conditions => visible.conditions)
    end
    @sidebar_queries
  end

  def query_links(title, queries)
    # links to #index on issues/show
    url_params = controller_name == 'issues' ? {:controller => 'issues', :action => 'index', :project_id => @project} : params

    content_tag('h3', h(title)) +
      queries.collect {|query|
          link_to(h(query.name), url_params.merge(:query_id => query))
        }.join('<br />')
  end

  def render_sidebar_queries
    out = ''
    queries = sidebar_queries.select {|q| !q.is_public?}
    out << query_links(l(:label_my_queries), queries) if queries.any?
    queries = sidebar_queries.select {|q| q.is_public?}
    out << query_links(l(:label_query_plural), queries) if queries.any?
    out
  end

  # Find the name of an associated record stored in the field attribute
  def find_name_by_reflection(field, id)
    association = Issue.reflect_on_association(field.to_sym)
    if association
      record = association.class_name.constantize.find_by_id(id)
      return record.name if record
    end
  end

  # Renders issue children recursively
  def render_api_issue_children(issue, api)
    return if issue.leaf?
    api.array :children do
      issue.children.each do |child|
        api.issue(:id => child.id) do
          api.tracker(:id => child.tracker_id, :name => child.tracker.name) unless child.tracker.nil?
          api.subject child.subject
          render_api_issue_children(child, api)
        end
      end
    end
  end

  def issues_to_csv(issues, project = nil)
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')
    decimal_separator = l(:general_csv_decimal_separator)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  l(:field_status),
                  l(:field_project),
                  l(:field_tracker),
                  l(:field_priority),
                  l(:field_subject),
                  l(:field_assigned_to),
                  l(:field_category),
                  l(:field_fixed_version),
                  l(:field_author),
                  l(:field_start_date),
                  l(:field_due_date),
                  l(:field_done_ratio),
                  l(:field_estimated_hours),
                  l(:field_parent_issue),
                  l(:field_created_on),
                  l(:field_updated_on)
                  ]
      # Export project custom fields if project is given
      # otherwise export custom fields marked as "For all projects"
      custom_fields = project.nil? ? IssueCustomField.for_all : project.all_issue_custom_fields
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      headers << l(:field_description)
      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      issues.each do |issue|
        fields = [issue.id,
                  issue.status.name,
                  issue.project.name,
                  issue.tracker.name,
                  issue.priority.name,
                  issue.subject,
                  issue.assigned_to,
                  issue.category,
                  issue.fixed_version,
                  issue.author.name,
                  format_date(issue.start_date),
                  format_date(issue.due_date),
                  issue.done_ratio,
                  issue.estimated_hours.to_s.gsub('.', decimal_separator),
                  issue.parent_id,
                  format_time(issue.created_on),
                  format_time(issue.updated_on)
                  ]
        custom_fields.each {|f| fields << show_value(issue.custom_value_for(f)) }
        fields << issue.description
        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export
  end

  def send_notification_option
    content_tag(:p,
                content_tag(:label,
                            l(:label_notify_member_plural), :for => 'send_notification') +
                hidden_field_tag('send_notification', '0', :id => nil) +
                check_box_tag('send_notification', '1', true))


  end
end
