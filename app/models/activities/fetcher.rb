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

module Activities
  # Class used to retrieve activity events
  class Fetcher
    attr_reader :user, :project, :scope

    def self.constantized_providers
      @constantized_providers ||= Hash.new { |h, k| h[k] = OpenProject::Activity.providers[k].map(&:constantize) }
    end

    def initialize(user, options = {})
      options.assert_valid_keys(:project, :with_subprojects, :author, :scope)
      @user = user
      @project = options[:project]
      @options = options

      self.scope = options[:scope] || :all
    end

    # Returns an array of available event types
    def event_types
      @event_types ||= begin
                         if @project
                           OpenProject::Activity.available_event_types.select do |o|
                             @project.self_and_descendants.detect do |_p|
                               permissions = constantized_providers(o).map do |p|
                                 p.activity_provider_options[:permission]
                               end.compact

                               permissions.all? { |p| @user.allowed_to?(p, @project) }
                             end
                           end
                         else
                           OpenProject::Activity.available_event_types
                         end
                       end
    end

    # Returns an array of events for the given date range
    # sorted in reverse chronological order
    def events(from = nil, to = nil, limit: nil)
      events = events_from_providers(from, to, limit)

      eager_load_associations(events)

      sort_by_date(events)
    end

    protected

    # Sets the scope
    # Argument can be :all, :default or an array of event types
    def scope=(scope)
      case scope
      when :all
        @scope = event_types
      when :default
        default_scope!
      else
        @scope = scope & event_types
      end
    end

    # Resets the scope to the default scope
    def default_scope!
      @scope = OpenProject::Activity.default_event_types
    end

    def events_from_providers(from, to, limit)
      events = []

      @scope.each do |event_type|
        constantized_providers(event_type).each do |provider|
          events += provider.find_events(event_type, @user, from, to, @options.merge(limit: limit))
        end
      end

      events
    end

    def eager_load_associations(events)
      projects = projects_of_event_set(events)
      users = users_of_event_set(events)

      events.each do |e|
        e.event_author = users[e.author_id]&.first
        e.project = projects[e.project_id]&.first
      end
    end

    def projects_of_event_set(events)
      project_ids = events.map(&:project_id).compact.uniq

      if project_ids.any?
        Project.find(project_ids).group_by(&:id)
      else
        {}
      end
    end

    def users_of_event_set(events)
      user_ids = events.map(&:author_id).compact.uniq

      User.where(id: user_ids).group_by(&:id)
    end

    def sort_by_date(events)
      events.sort { |a, b| b.event_datetime <=> a.event_datetime }
    end

    def constantized_providers(event_type)
      self.class.constantized_providers[event_type]
    end
  end
end
