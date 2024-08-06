#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Widget::Table < Widget::Base
  extend Report::InheritedAttribute
  include ReportingHelper

  attr_accessor :fields, :mapping

  def initialize(query)
    raise ArgumentError, "Tables only work on CostQuery!" unless query.is_a? CostQuery

    super
  end

  def resolve_table
    if @subject.group_bys.empty?
      Widget::Table::EntryTable
    else
      Widget::Table::ReportTable
    end
  end

  def render
    write("<!-- table start -->".html_safe)
    if @subject.result.count <= 0
      write(content_tag(:div, "", class: "generic-table--no-results-container") do
        content_tag(:i, "", class: "icon-info1") +
          content_tag(:span, I18n.t(:no_results_title_text), class: "generic-table--no-results-title")
      end)
    else
      render_widget(resolve_table, @subject, @options.reverse_merge(to: @output))
    end
  end
end
