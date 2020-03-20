#-- encoding: UTF-8
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

  def self.acts_as_activity_provider(options = {})
    options.assert_valid_keys(:type, :permission, :activities, :aggregated)

    self.activity_provider_options = {
      type: name.underscore.pluralize,
      activities: [:activity],
      aggregated: false,
      permission: "view_#{name.underscore.pluralize}".to_sym
    }.merge(options)
  end

  def self.event_projection(journals_table)
    [
      journals_table[:id].as('event_id'),
      journals_table[:created_at].as('event_datetime'),
      journals_table[:user_id].as('event_author'),
      journals_table[:notes].as('event_description'),
      journals_table[:version].as('version'),
      journals_table[:journable_id].as('journable_id')
    ]
  end

  # Returns events of type event_type visible by user that occured between from and to
  def self.find_events(event_type, user, from, to, options)
    raise "#{name} can not provide #{event_type} events." if activity_provider_options[:type] != event_type

    provider_options = activity_provider_options.dup

    provider_options[:activities]
      .map { |activity| find_events_for_class(new, activity, provider_options, user, from, to, options) }
      .flatten
      .each { |e| e.event_type = event_type.dup.singularize unless e.event_type }
  end

  def self.find_events_for_class(provider, activity, provider_options, user, from, to, options)
    activity_journals_table = provider.activity_journals_table activity

    query = journals_table.join(activity_journals_table).on(journals_table[:id].eq(activity_journals_table[:journal_id]))
    query = query.where(journals_table[:journable_type].eq(provider.activitied_type(activity).name))

    unless activity_provider_options[:aggregated]
      provider.extend_event_query(query, activity) if provider.respond_to?(:extend_event_query)
    end

    provider.filter_for_event_datetime query, journals_table, activity_journals_table, from, to

    query = query.where(journals_table[:user_id].eq(options[:author].id)) if options[:author]

    query = join_with_projects_table(query, provider.projects_reference_table(activity))
    query = restrict_projects_by_selection(options, query)
    query = restrict_projects_by_permission(provider_options[:permission], query)
    query = restrict_projects_by_user(provider_options, user, query)

    if activity_provider_options[:aggregated]
      query = Journal::Scopes::AggregatedJournal.fetch(sql: query.dup.project('journals.*').to_sql).arel

      query = journals_table.from.from(query.as('journals'))
      query.join(activity_journals_table).on(journals_table[:id].eq(activity_journals_table[:journal_id]))
      provider.extend_event_query(query, activity) if provider.respond_to?(:extend_event_query)
      query = join_with_projects_table(query, provider.projects_reference_table(activity))
    end

    return [] if query.nil?

    Redmine::Hook.call_hook(:activity_fetcher_find_events_for_class,
                            activity: activity,
                            query: query,
                            user: user)

    query = query.order(journals_table[:id].desc)
    query = query.take(options[:limit]) if options[:limit]

    projection = event_projection(journals_table)
    projection << provider.event_query_projection(activity) if provider.respond_to?(:event_query_projection)

    query.project(projection)

    fill_events(provider, activity, ActiveRecord::Base.connection.select_all(query.to_sql))
  end

  def self.join_with_projects_table(query, project_ref_table)
    query.join(projects_table).on(projects_table[:id].eq(project_ref_table['project_id']))
  end

  def self.restrict_projects_by_selection(options, query)
    if (project = options[:project])
      stmt = projects_table[:id].eq(project.id)
      stmt = stmt.or(projects_table[:lft].gt(project.lft).and(projects_table[:rgt].lt(project.rgt))) if options[:with_subprojects]

      query = query.where(stmt)
    end

    query
  end

  def self.restrict_projects_by_permission(permission, query)
    perm = OpenProject::AccessControl.permission(permission)

    query = query.where(projects_table[:active].eq(true))

    if perm && perm.project_module
      m = EnabledModule.arel_table
      subquery = m.where(m[:name].eq(perm.project_module))
                   .project(m[:project_id])

      query = query.where(projects_table[:id].in(subquery))
    end

    query
  end

  def self.restrict_projects_by_user(options, user, query)
    return query if user.admin?

    stmt = nil
    perm = OpenProject::AccessControl.permission(options[:permission])
    is_member = options[:member]

    if user.logged?
      allowed_projects = []

      user.projects_by_role.each do |role, projects|
        allowed_projects << projects.map(&:id) if perm && role.allowed_to?(perm.name)
      end

      stmt = projects_table[:id].in(allowed_projects.flatten.uniq)
    end

    if perm && (Role.anonymous.allowed_to?(perm.name) || Role.non_member.allowed_to?(perm.name)) && !is_member
      public_project = projects_table[:public].eq(true)

      stmt = stmt ? stmt.or(public_project) : public_project
    end

    query = query.where(stmt)

    stmt ? query : nil
  end

  def self.fill_events(provider, activity, events)
    events.each_with_object([]) do |e, result|
      datetime = e['event_datetime'].is_a?(String) ? DateTime.parse(e['event_datetime']) : e['event_datetime']
      event = Activities::Event.new(self,
                                    nil,
                                    nil,
                                    e['event_description'],
                                    e['event_author'].to_i,
                                    nil,
                                    datetime,
                                    e['journable_id'],
                                    e['project_id'].to_i,
                                    nil,
                                    nil,
                                    nil,
                                    nil)

      begin
        result << (provider.respond_to?(:format_event) ? provider.format_event(event, e, activity) : event)
      rescue StandardError => e
        Rails.logger.error "Failed to format_event for #{event.inspect}: #{e}"
      end
    end
  end

  #############################################################################
  # Activities may need information not available in the journal table. Thus, #
  # if you need further information from different tables (e.g., projects     #
  # table) you may extend the query in this method.                           #
  #############################################################################
  def extend_event_query(_query, _activity); end

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

  def filter_for_event_datetime(query, journals_table, typed_journals_table, from, to)
    if from
      query = query.where(journals_table[:created_at].gteq(from))
    end

    if to
      query = query.where(journals_table[:created_at].lteq(to))
    end

    query
  end

  def activity_journals_table(_activity)
    @activity_journals_table ||= JournalManager.journal_class(activitied_type).arel_table
  end

  def activitied_type(_activity = nil)
    activity_type = self.class.name

    class_name = activity_type.demodulize
    class_name.gsub('ActivityProvider', '').constantize
  end

  def format_event(event, event_data, activity)
    %i[event_name event_title event_type event_description event_datetime event_path event_url].each do |a|
      event[a] = send(a, event_data, activity) if self.class.method_defined? a
    end

    event
  end

  protected

  def journal_table
    @journal_table ||= Journal.arel_table
  end

  # TODO: Dupliate of journal_table
  def self.journals_table
    Journal.arel_table
  end

  def activitied_table
    @activitied_table ||= activitied_type.arel_table
  end

  def work_packages_table
    @work_packages_table ||= WorkPackage.arel_table
  end

  def projects_table
    @projects_table ||= Project.arel_table
  end

  # TODO: Dupliate of instance method
  def self.projects_table
    @projects_table ||= Project.arel_table
  end

  def types_table
    @types_table = Type.arel_table
  end

  def statuses_table
    @statuses_table = Status.arel_table
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
