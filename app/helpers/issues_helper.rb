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
    @cached_label_status ||= Issue.human_attribute_name(:status)
    @cached_label_start_date ||= Issue.human_attribute_name(:start_date)
    @cached_label_due_date ||= Issue.human_attribute_name(:due_date)
    @cached_label_assigned_to ||= Issue.human_attribute_name(:assigned_to)
    @cached_label_priority ||= Issue.human_attribute_name(:priority)
    @cached_label_project ||= Issue.human_attribute_name(:project)

    (link_to_work_package(issue) + "<br /><br />
      <strong>#{@cached_label_project}</strong>: #{link_to_project(issue.project)}<br />
      <strong>#{@cached_label_status}</strong>: #{h(issue.status.name)}<br />
      <strong>#{@cached_label_start_date}</strong>: #{format_date(issue.start_date)}<br />
      <strong>#{@cached_label_due_date}</strong>: #{format_date(issue.due_date)}<br />
      <strong>#{@cached_label_assigned_to}</strong>: #{h(issue.assigned_to)}<br />
      <strong>#{@cached_label_priority}</strong>: #{h(issue.priority.name)}".html_safe)
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
             content_tag('td',
                         "<label>#{l(:description_select_issue) + " #" + child.id.to_s}" +
                         check_box_tag('ids[]', child.id, false, :id => nil) + '</label>',
                         :class => 'checkbox') +
             content_tag('td', link_to_issue(child, :truncate => 60), :class => 'subject') +
             content_tag('td', h(child.status)) +
             content_tag('td', link_to_user(child.assigned_to)) +
             content_tag('td', progress_bar(child.done_ratio, :width => '80px', :legend => "#{child.done_ratio}%")),
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
    s.html_safe
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
    url_params = controller_name == 'issues' ? {:controller => '/issues', :action => 'index', :project_id => @project} : params

    content_tag('h3', title) +
      queries.collect {|query|
          link_to(query.name, url_params.merge(:query_id => query))
        }.join('<br />').html_safe
  end

  def render_sidebar_queries
    out = ''
    queries = sidebar_queries.reject(&:is_public?)
    out << query_links(l(:label_my_queries), queries) if queries.any?
    queries = sidebar_queries.select(&:is_public?)
    out << query_links(l(:label_query_plural), queries) if queries.any?
    out.html_safe
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
          api.type(:id => child.type_id, :name => child.type.name) unless child.type.nil?
          api.subject child.subject
          render_api_issue_children(child, api)
        end
      end
    end
  end

  def render_issue_tree_row(issue, level, relation)
    css_classes = ["issue"]
    css_classes << "issue-#{issue.id}"
    css_classes << "idnt" << "idnt-#{level}" if level > 0

    if relation == "root"
      issue_text = link_to("#{h(issue.type.name)} ##{issue.id}",
                             'javascript:void(0)',
                             :style => "color:inherit; font-weight: bold; text-decoration:none; cursor:default;",
                             :class => issue.css_classes)
    else
      title = []

      if relation == "parent"
        title << content_tag(:span, l(:description_parent_issue), :class => "hidden-for-sighted")
      elsif relation == "child"
        title << content_tag(:span, l(:description_sub_issue), :class => "hidden-for-sighted")
      end
      title << h(issue.type.name)
      title << "##{issue.id}"

      issue_text = link_to(title.join(' ').html_safe, issue_path(issue), :class => issue.css_classes)
    end
    issue_text << ": "
    issue_text << truncate(issue.subject, :length => 60)

    content_tag :tr, :class => css_classes.join(' ') do
      concat content_tag :td, check_box_tag("ids[]", issue.id, false, :id => nil), :class => 'checkbox'
      concat content_tag :td, issue_text, :class => 'subject'
      concat content_tag :td, h(issue.status)
      concat content_tag :td, link_to_user(issue.assigned_to)
      concat content_tag :td, link_to_version(issue.fixed_version)
    end
  end

  def issues_to_csv(issues, project = nil)
    decimal_separator = l(:general_csv_decimal_separator)
    export = CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  Issue.human_attribute_name(:status),
                  Issue.human_attribute_name(:project),
                  Issue.human_attribute_name(:type),
                  Issue.human_attribute_name(:priority),
                  Issue.human_attribute_name(:subject),
                  Issue.human_attribute_name(:assigned_to),
                  Issue.human_attribute_name(:category),
                  Issue.human_attribute_name(:fixed_version),
                  Issue.human_attribute_name(:author),
                  Issue.human_attribute_name(:start_date),
                  Issue.human_attribute_name(:due_date),
                  Issue.human_attribute_name(:done_ratio),
                  Issue.human_attribute_name(:estimated_hours),
                  Issue.human_attribute_name(:parent_issue),
                  Issue.human_attribute_name(:created_at),
                  Issue.human_attribute_name(:updated_at)
                  ]
      # Export project custom fields if project is given
      # otherwise export custom fields marked as "For all projects"
      custom_fields = project.nil? ? WorkPackageCustomField.for_all : project.all_work_package_custom_fields
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      headers << CustomField.human_attribute_name(:description)
      csv << headers.collect {|c| begin; c.to_s.encode(l(:general_csv_encoding), 'UTF-8'); rescue; c.to_s; end }
      # csv lines
      issues.each do |issue|
        fields = [issue.id,
                  issue.status.name,
                  issue.project.name,
                  issue.type.name,
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
                  format_time(issue.created_at),
                  format_time(issue.updated_at)
                  ]
        custom_fields.each {|f| fields << show_value(issue.custom_value_for(f)) }
        fields << issue.description
        csv << fields.collect {|c| begin; c.to_s.encode(l(:general_csv_encoding), 'UTF-8'); rescue; c.to_s; end }
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

  def entries_for_filter_select_sorted(query)
    [["",""]] + query.available_filters.collect{|field| [ field[1][:name] || Issue.human_attribute_name(field[0]), field[0]] unless query.has_filter?(field[0])}.compact.sort_by do |el|
      ActiveSupport::Inflector.transliterate(el[0]).downcase
    end
  end

  def value_overridden_by_children?(attrib)
    Issue::ATTRIBS_WITH_VALUES_FROM_CHILDREN.include? attrib
  end

  def attrib_disabled?(issue, attrib)
    value_overridden_by_children?(attrib) && !(issue.new_record? || issue.leaf?)
  end
end
