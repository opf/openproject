#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Widget::Table < Widget::Base
  extend Report::InheritedAttribute
  include ReportingHelper

  attr_accessor :debug
  attr_accessor :fields
  attr_accessor :mapping

  def initialize(query)
    raise ArgumentError, 'Tables only work on Reports!' unless query.is_a? Report
    super
  end

  def resolve_table
    if @subject.group_bys.size == 0
      self.class.detailed_table
    elsif @subject.group_bys.size == 1
      self.class.simple_table
    else
      self.class.fancy_table
    end
  end

  def self.detailed_table(klass = nil)
    @@detail_table = klass if klass
    defined?(@@detail_table) ? @@detail_table : fancy_table
  end

  def self.simple_table(klass = nil)
    @@simple_table = klass if klass
    defined?(@@simple_table) ? @@simple_table : fancy_table
  end

  def self.fancy_table(klass = nil)
    @@fancy_table = klass if klass
    @@fancy_table
  end
  fancy_table Widget::Table::ReportTable

  def render
    write('<!-- table start -->')
    if @subject.result.count <= 0
      write(content_tag(:div, '', class: 'generic-table--no-results-container') do
        content_tag(:i, '', class: 'icon-info1') + content_tag(:h2, l(:no_results_title_text), class: 'generic-table--no-results-title')
      end)
    else
      str = render_widget(resolve_table, @subject, @options.reverse_merge(to: @output))
      @cache_output.write(str.html_safe) if @cache_output
    end
  end
end
