#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module OpenProject
  module Acts
    module Watchable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Marks an ActiveRecord::Model as watchable
        # A watchable model has association with users (watchers) who wish to
        # be informed of changes on it.
        #
        # This also creates the routes necessary for watching/unwatching by
        # adding the model's name to routes. This e.g leads to the following
        # routes when marking issues as watchable:
        #   POST:     issues/1/watch
        #   DELETE:   issues/1/unwatch
        #   GET/POST: issues/1/watchers/new
        #   DELETE:   issues/1/watchers/1
        #
        # params:
        #   options:
        #     permission: overrides the permission used to determine whether a user
        #                 is allowed to watch

        def acts_as_watchable(options = {})
          return if included_modules.include?(InstanceMethods)

          acts_as_watchable_enforce_project_association

          class_eval do
            prepend InstanceMethods

            has_many :watchers, as: :watchable, dependent: :delete_all, validate: false
            has_many :watcher_users, through: :watchers, source: :user, validate: false

            scope :watched_by, ->(user_id) {
              includes(:watchers)
                .where(watchers: { user_id: })
            }

            class_attribute :acts_as_watchable_options

            self.acts_as_watchable_options = options
          end

          Registry.add(self)
        end

        def acts_as_watchable_enforce_project_association
          return if reflect_on_association(:project)

          raise <<-MESSAGE
            The #{self} model does not have an association to the Project model.

            acts_as_watchable requires the including model to have such an association.

            If no direct association exists, consider adding a
              has_one :project, through: ...
            association.
          MESSAGE
        end
      end

      module InstanceMethods
        def self.prepended(base)
          base.extend AddClassMethods
        end

        def possible_watcher?(user)
          user.allowed_based_on_permission_context?(self.class.acts_as_watchable_permission,
                                                    project:,
                                                    entity: self)
        end

        # Returns all users that could potentially be watchers.
        # This includes those already added as watchers.
        #
        # Admins are excluded at least for non public projects
        # because while they have the right to be added as watchers having
        # them pop up in every project would be weird.
        def possible_watcher_users
          active_scope = Principal.not_locked.user

          allowed_scope = if project.public?
                            User.allowed(self.class.acts_as_watchable_permission, project)
                          else
                            User.allowed_members_on_work_package(self.class.acts_as_watchable_permission, self)
                          end

          active_scope.where(id: allowed_scope)
        end

        # Returns an array of users that are proposed as watchers
        def addable_watcher_users
          possible_watcher_users.where.not(id: watcher_users.pluck(:id))
        end

        # Adds user as a watcher
        def add_watcher(user)
          watchers << Watcher.new(user:, watchable: self) unless watchers.map(&:user_id).include?(user.id)
        end

        # Removes user from the watchers list
        def remove_watcher(user)
          return nil unless user&.is_a?(User)

          watchers_to_delete = watchers.find_all { |watcher| watcher.user == user }
          watchers_to_delete.each(&:delete)
          watchers.reload
          watchers_to_delete.count
        end

        # Adds/removes watcher
        def set_watcher(user, watching = true)
          watching ? add_watcher(user) : remove_watcher(user)
        end

        # Overrides watcher_user_ids= to make user_ids uniq
        def watcher_user_ids=(user_ids)
          if user_ids.is_a?(Array)
            user_ids = user_ids.uniq
          end

          super
        end

        # Returns true if object is watched by +user+
        def watched_by?(user)
          user.present? &&
            ((watchers.loaded? && watchers.map(&:user_id).any? { |uid| uid == user.id }) ||
              watcher_user_ids.any? { |uid| uid == user.id })
        end

        module AddClassMethods
          def acts_as_watchable_permission
            acts_as_watchable_options[:permission] || :"view_#{name.underscore.pluralize}"
          end
        end
      end
    end
  end
end
