# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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
  
  def render_issue_tooltip(issue)
    @cached_label_status ||= l(:field_status)
    @cached_label_start_date ||= l(:field_start_date)
    @cached_label_due_date ||= l(:field_due_date)
    @cached_label_assigned_to ||= l(:field_assigned_to)
    @cached_label_priority ||= l(:field_priority)
    
    link_to_issue(issue) + "<br /><br />" +
      "<strong>#{@cached_label_status}</strong>: #{issue.status.name}<br />" +
      "<strong>#{@cached_label_start_date}</strong>: #{format_date(issue.start_date)}<br />" +
      "<strong>#{@cached_label_due_date}</strong>: #{format_date(issue.due_date)}<br />" +
      "<strong>#{@cached_label_assigned_to}</strong>: #{issue.assigned_to}<br />" +
      "<strong>#{@cached_label_priority}</strong>: #{issue.priority.name}"
  end
    
  def render_issue_subject_with_tree(issue)
    s = ''
    issue.ancestors.each do |ancestor|
      s << '<div>' + content_tag('p', link_to_issue(ancestor))
    end
    s << '<div>' + content_tag('h3', h(issue.subject))
    s << '</div>' * (issue.ancestors.size + 1)
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
                                    :select => 'id, name',
                                    :order => "name ASC",
                                    :conditions => visible.conditions)
    end
    @sidebar_queries
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

  def show_detail(journal, detail, html = true)
    journal.render_detail(detail, html)
  end

  def gantt_zoom_link(gantt, in_or_out)
    img_attributes = {:style => 'height:1.4em; width:1.4em; margin-left: 3px;'} # em for accessibility

    case in_or_out
    when :in
      if gantt.zoom < 4
        link_to_remote(l(:text_zoom_in) + image_tag('zoom_in.png', img_attributes.merge(:alt => l(:text_zoom_in))),
                       {:url => gantt.params.merge(:zoom => (gantt.zoom+1)), :update => 'content'},
                       {:href => url_for(gantt.params.merge(:zoom => (gantt.zoom+1)))})
      else
        l(:text_zoom_in) +
          image_tag('zoom_in_g.png', img_attributes.merge(:alt => l(:text_zoom_in)))
      end
      
    when :out
      if gantt.zoom > 1
        link_to_remote(l(:text_zoom_out) + image_tag('zoom_out.png', img_attributes.merge(:alt => l(:text_zoom_out))),
                       {:url => gantt.params.merge(:zoom => (gantt.zoom-1)), :update => 'content'},
                       {:href => url_for(gantt.params.merge(:zoom => (gantt.zoom-1)))})
      else
        l(:text_zoom_out) +
          image_tag('zoom_out_g.png', img_attributes.merge(:alt => l(:text_zoom_out)))
      end
    end
  end
end
