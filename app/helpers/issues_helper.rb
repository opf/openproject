#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

module IssuesHelper
  include ApplicationHelper

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
    @cached_label_status ||= WorkPackage.human_attribute_name(:status)
    @cached_label_start_date ||= WorkPackage.human_attribute_name(:start_date)
    @cached_label_due_date ||= WorkPackage.human_attribute_name(:due_date)
    @cached_label_assigned_to ||= WorkPackage.human_attribute_name(:assigned_to)
    @cached_label_priority ||= WorkPackage.human_attribute_name(:priority)
    @cached_label_project ||= WorkPackage.human_attribute_name(:project)

    (link_to_work_package(issue) + "<br /><br />
      <strong>#{@cached_label_project}</strong>: #{link_to_project(issue.project)}<br />
      <strong>#{@cached_label_status}</strong>: #{h(issue.status.name)}<br />
      <strong>#{@cached_label_start_date}</strong>: #{format_date(issue.start_date)}<br />
      <strong>#{@cached_label_due_date}</strong>: #{format_date(issue.due_date)}<br />
      <strong>#{@cached_label_assigned_to}</strong>: #{h(issue.assigned_to)}<br />
      <strong>#{@cached_label_priority}</strong>: #{h(issue.priority.name)}".html_safe)
  end

  # Find the name of an associated record stored in the field attribute
  def find_name_by_reflection(field, id)
    association = WorkPackage.reflect_on_association(field.to_sym)
    if association
      record = association.class_name.constantize.find_by(id: id)
      return record.name if record
    end
  end

  def entries_for_filter_select_sorted(query)
    [['', '']] + query.available_work_package_filters.map { |field| [field[1][:name] || WorkPackage.human_attribute_name(field[0]), field[0]] unless query.has_filter?(field[0]) }.compact.sort_by { |el|
      ActiveSupport::Inflector.transliterate(el[0]).downcase
    }
  end

  def last_issue_note(issue)
    note_journals = issue.journals.select(&:notes?)
    return t(:text_no_notes) if note_journals.empty?
    note_journals.last.notes
  end
end
