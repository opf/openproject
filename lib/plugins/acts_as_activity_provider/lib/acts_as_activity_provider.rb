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

module Redmine
  module Acts
    module ActivityProvider
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_activity_provider(options = {})
          unless self.included_modules.include?(Redmine::Acts::ActivityProvider::InstanceMethods)
            cattr_accessor :activity_provider_options
            send :include, Redmine::Acts::ActivityProvider::InstanceMethods
          end

          options.assert_valid_keys(:type, :permission, :timestamp, :author_key, :find_options)
          self.activity_provider_options ||= {}

          # One model can provide different event types
          # We store these options in activity_provider_options hash
          event_type = options.delete(:type) || self.name.underscore.pluralize

          options[:permission] = "view_#{self.name.underscore.pluralize}".to_sym unless options.has_key?(:permission)
          options[:timestamp] ||= "#{table_name}.created_on"
          options[:find_options] ||= {}
          options[:author_key] = "#{table_name}.#{options[:author_key]}" if options[:author_key].is_a?(Symbol)
          self.activity_provider_options[event_type] = options
        end
      end

      Event = Struct.new(:title,
                         :description,
                         :author,
                         :datetime,
                         :project,
                         :type,
                         :url)

      def self.event_projection(j)
        [
          j[:id].as('event_id'),
          j[:created_at].as('event_datetime'),
          j[:user_id].as('event_author'),
          j[:notes].as('event_description'),
          j[:version].as('version'),
          j[:journable_id].as('journable_id')
        ]
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          # Returns events of type event_type visible by user that occured between from and to
          def find_events(event_type, user, from, to, options)
            raise "#{self.name} can not provide #{event_type} events." if activity_provider_options[event_type].nil?

            j = Arel::Table.new(:journals)
            ej = Arel::Table.new(JournalManager.journal_class(self).table_name)

            query = j.join(ej).on(j[:id].eq(ej[:journal_id]))
            query = query.where(j[:journable_type].eq(self.name))

            query = query.where(j[:created_at].gteq(from)) if from
            query = query.where(j[:created_at].lteq(to)) if to

            query = query.where(j[:user_id].eq(options[:author].id)) if options[:author]

            query = self.extend_event_query(j, ej, query) if self.respond_to? :extend_event_query

            # TODO: Implement permission scope

            query = query.order(j[:id]).take(options[:limit]) if options[:limit]

            projection = Redmine::Acts::ActivityProvider.event_projection(j)
            projection << self.event_projection(j, ej) if self.respond_to? :event_projection

            query.project(projection)

            return [] unless self.respond_to? :format_event_data
            self.format_event_data(ActiveRecord::Base.connection.execute(query.to_sql))
          end
        end
      end
    end
  end
end
