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

###############################################################################
# The base activity provider class provides a default implementation for the  #
# most common activity jobs. You may implement the following methods to set   #
# the respective activity details:                                            #
#  - event_name                                                               #
#  - event_title                                                              #
#  - event_type                                                               #
#  - event_description                                                        #
#  - event_datetime                                                           #
#  - event_path                                                               #
#  - event_url                                                                #
#                                                                             #
# See the comments on the methods to get additional information.              #
###############################################################################
class Activity::BaseActivityProvider
  include Redmine::Acts::ActivityProvider
  include Redmine::I18n
  include OpenProject::StaticRouting

  #############################################################################
  # Activities may need information not available in the journal table. Thus, #
  # if you need further information from different tables (e.g., projects     #
  # table) you may extend the query in this method.                           #
  #############################################################################
  def extend_event_query(_query, _activity)
  end

  #############################################################################
  # This method returns a list of columns that the activity query needs to    #
  # return, so the activity provider can actually create an activity object.  #
  # You must at least return the column containing the project reference with #
  # the alias 'project_id'.                                                   #
  #############################################################################
  def event_query_projection(_activity)
    []
  end

  #############################################################################
  # Override this method if the journal table does not contain a reference to #
  # the 'projects' table.                                                     #
  #############################################################################
  def projects_reference_table(activity)
    activity_journals_table(activity)
  end

  def activity_journals_table(_activity)
    @activity_journals_table ||= Arel::Table.new(JournalManager.journal_class(activitied_type).table_name)
  end

  def activitied_type(_activity = nil)
    activity_type = self.class.name
    namespace = activity_type.deconstantize

    class_name = activity_type.demodulize
    class_name.gsub('ActivityProvider', '').constantize
  end

  def format_event(event, event_data, activity)
    [:event_name, :event_title, :event_type, :event_description, :event_datetime, :event_path, :event_url].each do |a|
      event[a] = send(a, event_data, activity) if self.class.method_defined? a
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

  def work_packages_table
    @work_packages_table ||= Arel::Table.new(:work_packages)
  end

  def projects_table
    @projects_table ||= Arel::Table.new(:projects)
  end

  def types_table
    @types_table = Arel::Table.new(:types)
  end

  def statuses_table
    @statuses_table = Arel::Table.new(:statuses)
  end

  def activity_journal_projection_statement(column, name, activity)
    projection_statement(activity_journals_table(activity), column, name)
  end

  def projection_statement(table, column, name)
    table[column].as(name)
  end

  class UndefinedEventTypeError < StandardError; end
  def event_type(_event, _activity)
    raise UndefinedEventTypeError.new('Abstract method event_type called')
  end

  def event_name(event, activity)
    I18n.t(event_type(event, activity).underscore, scope: 'events')
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end
end
