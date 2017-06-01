#-- encoding: UTF-8
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
  module Activity
    # Class used to retrieve activity events
    class Fetcher
      attr_reader :user, :project, :scope

      # Needs to be unloaded in development mode
      @@constantized_providers = Hash.new { |h, k| h[k] = Redmine::Activity.providers[k].map(&:constantize) }

      def initialize(user, options = {})
        options.assert_valid_keys(:project, :with_subprojects, :author)
        @user = user
        @project = options[:project]
        @options = options

        @scope = event_types
      end

      # Returns an array of available event types
      def event_types
        return @event_types unless @event_types.nil?

        @event_types = Redmine::Activity.available_event_types
        if @project
          @event_types = @event_types.select { |o|
            @project.self_and_descendants.detect do |_p|
              permissions = constantized_providers(o).map { |p|
                p.activity_provider_options[o].try(:[], :permission)
              }.compact
              return @user.allowed_to?("view_#{o}".to_sym, @project) if permissions.blank?
              permissions.all? { |p| @user.allowed_to?(p, @project) }
            end
          }
        end
        @event_types
      end

      # Yields to filter the activity scope
      def scope_select(&_block)
        @scope = @scope.select { |t| yield t }
      end

      # Sets the scope
      # Argument can be :all, :default or an array of event types
      def scope=(s)
        case s
        when :all
          @scope = event_types
        when :default
          default_scope!
        else
          @scope = s & event_types
        end
      end

      # Resets the scope to the default scope
      def default_scope!
        @scope = Redmine::Activity.default_event_types
      end

      # Returns an array of events for the given date range
      # sorted in reverse chronological order
      def events(from = nil, to = nil, options = {})
        e = []
        @options[:limit] = options[:limit]

        @scope.each do |event_type|
          constantized_providers(event_type).each do |provider|
            e += provider.find_events(event_type, @user, from, to, @options)
          end
        end

        projects = Project.find(e.map(&:project_id).compact) if e.select { |e| !e.project_id.nil? }
        users = User.find(e.map(&:author_id).compact)

        e.each do |e|
          e.event_author = users.find { |u| u.id == e.author_id } if e.author_id
          e.project = projects.find { |p| p.id == e.project_id } if e.project_id
        end

        e.sort! do |a, b| b.event_datetime <=> a.event_datetime end
        e
      end

      private

      def constantized_providers(event_type)
        @@constantized_providers[event_type]
      end
    end
  end
end
