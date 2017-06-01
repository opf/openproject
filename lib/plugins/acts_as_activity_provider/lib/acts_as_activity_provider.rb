#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module Acts
    module ActivityProvider
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_activity_provider(options = {})
          unless included_modules.include?(Redmine::Acts::ActivityProvider::InstanceMethods)
            cattr_accessor :activity_provider_options
            send :include, Redmine::Acts::ActivityProvider::InstanceMethods
          end

          options.assert_valid_keys(:type, :permission, :activities)
          self.activity_provider_options ||= {}

          # One model can provide different event types
          # We store these options in activity_provider_options hash
          event_type = options.delete(:type) || name.underscore.pluralize

          options[:activities] = options.delete(:activities) || [:activity]
          options[:permission] = "view_#{name.underscore.pluralize}".to_sym unless options.has_key?(:permission)
          self.activity_provider_options[event_type] = options
        end
      end

      Event = Struct.new(:provider,
                         :event_name,
                         :event_title,
                         :event_description,
                         :author_id,
                         :event_author,
                         :event_datetime,
                         :journable_id,
                         :project_id,
                         :project,
                         :event_type,
                         :event_path,
                         :event_url)

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

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          # Returns events of type event_type visible by user that occured between from and to
          def find_events(event_type, user, from, to, options)
            raise "#{name} can not provide #{event_type} events." if activity_provider_options[event_type].nil?

            result = []

            provider_options = activity_provider_options[event_type].dup

            provider_options[:activities].each do |activity|
              result << find_events_for_class(new, activity, provider_options, user, from, to, options)
            end

            result.flatten!
            result.each do |e| e.event_type = event_type.dup.singularize unless e.event_type end
            result
          end

          private

          def find_events_for_class(provider, activity, provider_options, user, from, to, options)
            activity_journals_table = provider.activity_journals_table activity

            query = journals_table.join(activity_journals_table).on(journals_table[:id].eq(activity_journals_table[:journal_id]))
            query = query.where(journals_table[:journable_type].eq(provider.activitied_type(activity).name))

            query = query.where(journals_table[:created_at].gteq(from)) if from
            query = query.where(journals_table[:created_at].lteq(to)) if to

            query = query.where(journals_table[:user_id].eq(options[:author].id)) if options[:author]

            provider.extend_event_query(query, activity) if provider.respond_to?(:extend_event_query)

            query = join_with_projects_table(query, provider.projects_reference_table(activity))
            query = restrict_projects_by_selection(options, query)
            query = restrict_projects_by_permission(provider_options[:permission], query)
            query = restrict_projects_by_user(provider_options, user, query)

            return [] if query.nil?

            Redmine::Hook.call_hook(:activity_fetcher_find_events_for_class,
                                    activity: activity,
                                    query: query,
                                    user: user)

            query = query.order(journals_table[:id].desc)
            query = query.take(options[:limit]) if options[:limit]

            projection = Redmine::Acts::ActivityProvider.event_projection(journals_table)
            projection << provider.event_query_projection(activity) if provider.respond_to?(:event_query_projection)

            query.project(projection)

            fill_events(provider, activity, ActiveRecord::Base.connection.select_all(query.to_sql))
          end

          def join_with_projects_table(query, project_ref_table)
            query = query.join(projects_table).on(projects_table[:id].eq(project_ref_table['project_id']))
            query
          end

          def restrict_projects_by_selection(options, query)
            if project = options[:project]
              stmt = projects_table[:id].eq(project.id)
              stmt = stmt.or(projects_table[:lft].gt(project.lft).and(projects_table[:rgt].lt(project.rgt))) if options[:with_subprojects]

              query = query.where(stmt)
            end

            query
          end

          def restrict_projects_by_permission(permission, query)
            perm = Redmine::AccessControl.permission(permission)

            query = query.where(projects_table[:status].eq(Project::STATUS_ACTIVE))

            if perm && perm.project_module
              m = EnabledModule.arel_table
              subquery = m.where(m[:name].eq(perm.project_module))
                         .project(m[:project_id])

              query = query.where(projects_table[:id].in(subquery))
            end

            query
          end

          def restrict_projects_by_user(options, user, query)
            return query if user.admin?

            stmt = nil
            perm = Redmine::AccessControl.permission(options[:permission])
            is_member = options[:member]
            original_query = query.dup

            if user.logged?
              allowed_projects = []

              user.projects_by_role.each do |role, projects|
                allowed_projects << projects.map(&:id) if perm && role.allowed_to?(perm.name)
              end

              stmt = projects_table[:id].in(allowed_projects.flatten.uniq)
            end

            if perm && (Role.anonymous.allowed_to?(perm.name) || Role.non_member.allowed_to?(perm.name)) && !is_member
              public_project = projects_table[:is_public].eq(true)

              stmt = stmt ? stmt.or(public_project) : public_project
            end

            query = query.where(stmt)

            stmt ? query : nil
          end

          def fill_events(provider, activity, events)
            events.each_with_object([]) do |e, result|
              datetime = e['event_datetime'].is_a?(String) ? DateTime.parse(e['event_datetime']) : e['event_datetime']
              event = Redmine::Acts::ActivityProvider::Event.new(self,
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

              result << ((provider.respond_to?(:format_event)) ? provider.format_event(event, e, activity) : event)
            end
          end

          def projects_table
            Project.arel_table
          end

          def journals_table
            Journal.arel_table
          end
        end
      end
    end
  end
end
