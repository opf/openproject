# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
class Activities::BaseActivityProvider
  include I18n
  include Redmine::I18n
  include OpenProject::StaticRouting

  class_attribute :activity_provider_options

  # Returns events of type event_type visible by user that occurred between from and to
  def self.find_events(event_type, user, from, to, options)
    raise "#{name} can not provide #{event_type} events." if activity_provider_options[:type] != event_type

    activity_provider_options[:activities]
      .map { |activity| new(activity).find_events(user, from, to, options) }
      .flatten
  end

  def initialize(activity)
    self.activity = activity
  end

  def self.activity_provider_for(options = {})
    options.assert_valid_keys(:type, :permission, :activities)

    self.activity_provider_options = {
      type: name.underscore.pluralize,
      activities: [:activity],
      permission: :"view_#{name.underscore.pluralize}"
    }.merge(options)
  end

  def find_events(user, from, to, options)
    query = event_selection_query(user, from, to, options)
    query = apply_order(query)
    query = apply_limit(query, options)
    query = apply_event_projection(query)
    fill_events(query)
  end

  def fill_events(events_query)
    ActiveRecord::Base.connection.select_all(events_query.to_sql).map do |e|
      params = event_params(e)

      Activities::Event.new(**params) if params
    end
  end

  #############################################################################
  # Activities may need information not available in the journal table. Thus, #
  # if you need further information from different tables (e.g., projects     #
  # table) you may extend the query in this method.                           #
  #############################################################################
  def extend_event_query(query)
    query
  end

  #############################################################################
  # This method returns a list of columns that the activity query needs to    #
  # return, so the activity provider can actually create an activity object.  #
  # You must at least return the column containing the project reference with #
  # the alias 'project_id'.                                                   #
  #############################################################################
  def event_query_projection
    []
  end

  def event_datetime(event)
    event['event_datetime'].is_a?(String) ? DateTime.parse(event['event_datetime']) : event['event_datetime']
  end

  def event_type(_event_data)
    activity_provider_options[:type]
  end

  #############################################################################
  # Override this method if the journal table does not contain a reference to #
  # the 'projects' table.                                                     #
  #############################################################################
  def projects_reference_table
    activity_journals_table
  end

  #############################################################################
  # Override this method if the project reference field in the projects       #
  # reference table is different from 'project_id'                            #
  #############################################################################
  def project_id_reference_field
    'project_id'
  end

  def activitied_type
    class_name = self.class.name.demodulize
    class_name.gsub('ActivityProvider', '').constantize
  end

  protected

  def event_selection_query(user, from, to, options)
    query = journals_with_data_query
    query = extend_event_query(query)
    query = filter_for_event_datetime(query, from, to)
    query = restrict_user(query, options)
    restrict_projects(query, user, options)
  end

  def apply_event_projection(query)
    projection = event_projection
    projection += event_query_projection

    query.project(projection)
  end

  def apply_limit(query, options)
    if options[:limit]
      query.take(options[:limit])
    else
      query
    end
  end

  def filter_for_event_datetime(query, from, to)
    query = query.where(journals_table[:created_at].gteq(from)) if from
    query = query.where(journals_table[:created_at].lteq(to)) if to

    query
  end

  def apply_order(query)
    query.order(journals_table[:id].desc)
  end

  def event_params(event_data)
    params = { provider: self,
               event_id: event_data['event_id'],
               event_description: event_data['event_description'],
               author_id: event_data['author_id'].to_i,
               journable_id: event_data['journable_id'],
               project_id: event_data['project_id'].to_i }

    %i[event_name event_title event_type event_description event_datetime event_path event_url].each do |a|
      params[a] = send(a, event_data) if self.class.method_defined? a
    end

    params
  rescue StandardError => e
    Rails.logger.error "Failed to deduce event params for #{event_data.inspect}: #{e}"
  end

  def event_projection
    [[:id, 'event_id'],
     [:created_at, 'event_datetime'],
     [:user_id, 'author_id'],
     [:notes, 'event_description'],
     [:version, 'version'],
     [:journable_id, 'journable_id']].map do |column, alias_name|
      journals_table[column].as(alias_name)
    end
  end

  def restrict_user(query, options)
    query = query.where(journals_table[:user_id].eq(options[:author].id)) if options[:author]
    query
  end

  def restrict_projects(query, user, options)
    query.join(restrict_projects_query(user, options).as(projects_table.name))
         .on(projects_table[:id].eq(projects_reference_table[project_id_reference_field]))
  end

  def restrict_projects_query(user, options)
    projects_table.project(Arel.star)
      .then { |query| restrict_projects_by_selection(options, query) }
      .then { |query| restrict_projects_by_activity_module(query) }
      .then { |query| restrict_projects_by_permission(query, user) }
  end

  def restrict_projects_by_selection(options, query)
    if (project = options[:project])
      query = query.where(project.project_condition(options[:with_subprojects]))
    end

    query
  end

  def restrict_projects_by_activity_module(query)
    # Have to use the string based where here as the resulting
    # sql would otherwise expect a parameter for the prepared statement.
    query.where(projects_table[:id].in(EnabledModule.where("name = 'activity'").select(:project_id).arel))
  end

  def restrict_projects_by_permission(query, user)
    perm = activity_provider_options[:permission]

    query.where(projects_table[:id].in(Project.allowed_to(user, perm).select(:id).arel))
  end

  attr_accessor :activity

  def journals_with_data_query
    join_activity_journals_table(journals_table)
      .where(journals_table[:journable_type].eq(activitied_type.name))
  end

  def join_activity_journals_table(query)
    query
      .join(activity_journals_table)
      .on(journals_table[:data_id].eq(activity_journals_table[:id])
                                  .and(journals_table[:data_type]).eq(activitied_type.journal_class.name))
  end

  def journals_table
    Journal.arel_table
  end

  def activitied_table
    @activitied_table ||= activitied_type.arel_table
  end

  def projects_table
    @projects_table ||= Project.arel_table
  end

  def enabled_modules_table
    @enabled_modules_table ||= EnabledModule.arel_table
  end

  def activity_journals_table
    @activity_journals_table ||= activitied_type.journal_class.arel_table
  end

  def activity_journal_projection_statement(column, name)
    projection_statement(activity_journals_table, column, name)
  end

  def projection_statement(table, column, name)
    table[column].as(name)
  end

  def event_name(event)
    @event_names ||= {}
    @event_names[event_type(event)] ||= I18n.t(event_type(event).underscore, scope: 'events')
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end
end
