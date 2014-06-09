#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

#-- encoding: UTF-8
# ActsAsWatchable
module Redmine
  module Acts
    module Watchable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Marks an ActiveRecord::Model as watchable
        # A watchable model has association with users (watchers) who wish to be informed of changes on it.
        #
        # This also creates the routes necessary for watching/unwatching by adding the model's name to routes. This
        # e.g leads to the following routes when marking issues as watchable:
        #   POST:     issues/1/watch
        #   DELETE:   issues/1/unwatch
        #   GET/POST: issues/1/watchers/new
        #   DELETE:   issues/1/watchers/1
        # Use the :route_prefix option to change the model prefix, e.g. from issues to tickets
        #
        # params:
        #   options:
        #     route_prefix: overrides the route calculation which would normally use the models name.

        def acts_as_watchable(options = {})
          return if self.included_modules.include?(Redmine::Acts::Watchable::InstanceMethods)
          class_eval do
            has_many :watchers, :as => :watchable, :dependent => :delete_all
            has_many :watcher_users, :through => :watchers, :source => :user, :validate => false

            scope :watched_by, lambda { |user_id|
              { :include => :watchers,
                :conditions => ["#{Watcher.table_name}.user_id = ?", user_id] }
            }
            attr_protected :watcher_ids, :watcher_user_ids if accessible_attributes.nil?

            class_attribute :acts_as_watchable_options
            self.acts_as_watchable_options = options
          end
          send :include, Redmine::Acts::Watchable::InstanceMethods
          alias_method_chain :watcher_user_ids=, :uniq_ids
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def watching_permitted_to_all_users_message
          "Let all users watch me. If this is unintended, implement :visible? on #{self.class.name}"
        end

        def possible_watcher?(user)
          if respond_to?(:visible?)
            visible?(user)
          else
            warn watching_permitted_to_all_users_message
          end
        end

        def possible_watcher_users
          permission = self.class.acts_as_watchable_options[:permission]

          User.allowed(permission, self.project, admin_pass: false)
              .not_builtin
              .order_by_name
              .select_only_name_attributes
        end

        # Returns an array of users that are proposed as watchers
        def addable_watcher_users
          possible_watcher_users - self.watcher_users
        end

        # Adds user as a watcher
        def add_watcher(user)
          self.watchers << Watcher.new(:user => user, :watchable => self)
        end

        # Removes user from the watchers list
        def remove_watcher(user)
          return nil unless user && user.is_a?(User)
          watchers_to_delete = self.watchers.find_all{|watcher| watcher.user == user}
          watchers_to_delete.each(&:delete)
          self.watchers(true)
          watchers_to_delete.count
        end

        # Adds/removes watcher
        def set_watcher(user, watching=true)
          watching ? add_watcher(user) : remove_watcher(user)
        end

        # Overrides watcher_user_ids= to make user_ids uniq
        def watcher_user_ids_with_uniq_ids=(user_ids)
          if user_ids.is_a?(Array)
            user_ids = user_ids.uniq
          end
          send :watcher_user_ids_without_uniq_ids=, user_ids
        end

        # Returns true if object is watched by +user+
        def watched_by?(user)
          !!(user &&
             (self.watchers.loaded? && self.watchers.map(&:user_id).any?{ |uid| uid == user.id } ||
              self.watcher_user_ids.any?{|uid| uid == user.id }))
        end

        # Returns an array of watchers' email addresses
        def watcher_recipients
          notified = watcher_users.active.where(['mail_notification != ?', 'none'])
          notified.select! {|user| possible_watcher?(user)}

          notified.collect(&:mail).compact
        end

        module ClassMethods; end
      end
    end
  end
end
