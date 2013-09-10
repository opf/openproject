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

  def render_descendants_tree(issue)
    s = '<form><table class="list issues">'
    issue_list(issue.descendants.sort_by(&:lft)) do |child, level|
      s << content_tag('tr',
             content_tag('td',
                         "<label>#{l(:description_select_work_package) + " #" + child.id.to_s}" +
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
