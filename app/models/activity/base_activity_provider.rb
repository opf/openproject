#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

class Activity::BaseActivityProvider
  include Redmine::Acts::ActivityProvider

  def extend_event_query(query)
  end

  def event_query_projection
    []
  end

  def projects_reference_table
    activity_journals_table
  end

  def format_event(event, event_data)
  end

  def activity_journals_table
    @activity_journals_table ||= Arel::Table.new(JournalManager.journal_class(activitied_type).table_name)
  end

  def activitied_type
    activity_type = self.class.name
    namespace = activity_type.deconstantize

    class_name = activity_type.demodulize
    class_name.gsub('ActivityProvider', '').constantize
  end

  def format_event(event, event_data)
    [:event_title, :event_type, :event_description, :event_datetime, :event_path, :event_url].each do |a|
      event[a] = self.send(a, event_data) if self.class.method_defined? a
    end

    event
  end

  protected

  def journal_table
    @journal_table ||= Arel::Table.new(:journals)
  end

  def activitied_table
    @activitied_table ||= Arel::Table.new(activitied_type.table_name)
  end

  def activity_journal_projection_statement(column, name)
    projection_statement(activity_journals_table, column, name)
  end

  def projection_statement(table, column, name)
    table[column].as(name)
  end
end
