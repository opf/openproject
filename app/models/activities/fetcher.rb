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
      @event_types ||=
        if @project
          OpenProject::Activity.available_event_types.select do |o|
            permissions = constantized_providers(o).filter_map do |activity_provider|
              activity_provider.activity_provider_options[:permission]
            end
            permissions.all? { |p| @user.allowed_in_project?(p, @project) }
          end
        else
          OpenProject::Activity.available_event_types.to_a
        end
    end

    # Returns an array of events for the given date range
    # sorted in reverse chronological order
    def events(from: nil, to: nil, limit: nil)
      events = events_from_providers(from, to, limit)

      eager_load_associations(events)

      sort_by_most_recent_first(events)
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
      @scope = OpenProject::Activity.default_event_types.to_a
    end

    def events_from_providers(from, to, limit)
      events = []

      @scope.each do |event_type|
        constantized_providers(event_type).each do |provider|
          events += provider.find_events(event_type, @user, from, to, @options.merge(limit:))
        end
      end

      events
    end

    def eager_load_associations(events)
      projects = projects_of_event_set(events)
      users = users_of_event_set(events)
      journals = journals_of_event_set(events)

      events.each do |e|
        e.event_author = users[e.author_id]
        e.project = projects[e.project_id]
        e.journal = journals[e.event_id]
      end
    end

    def projects_of_event_set(events)
      project_ids = events.filter_map(&:project_id).uniq

      Project.find(project_ids).index_by(&:id)
    end

    def users_of_event_set(events)
      user_ids = events.filter_map(&:author_id).uniq

      User.where(id: user_ids).index_by(&:id)
    end

    def journals_of_event_set(events)
      journal_ids = events.map(&:event_id)

      Journal
        .includes(:data, :customizable_journals, :attachable_journals, :bcf_comment)
        .find(journal_ids)
        .then { |journals| ::API::V3::Activities::ActivityEagerLoadingWrapper.wrap(journals) }
        .index_by(&:id)
    end

    def sort_by_most_recent_first(events)
      events.sort { |a, b| b.event_datetime <=> a.event_datetime }
    end

    def constantized_providers(event_type)
      self.class.constantized_providers[event_type]
    end
  end
end
