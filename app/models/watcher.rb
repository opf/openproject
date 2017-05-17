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

class Watcher < ActiveRecord::Base
  belongs_to :watchable, polymorphic: true
  belongs_to :user

  validates_presence_of :watchable, :user
  validates_uniqueness_of :user_id, scope: [:watchable_type, :watchable_id]

  validate :validate_active_user
  validate :validate_user_allowed_to_watch

  def self.prune(user: [], project_id: nil)
    user_ids = Array(user).compact.map { |u| u.is_a?(User) ? u.id : nil }.compact

    projects = project_id ? Project.where(id: project_id) : Project.all

    prune_project_related(user_ids, projects)
  end

  protected

  def validate_active_user
    # TODO add informative error message
    return if user.blank?
    errors.add :user_id, :invalid unless user.active_or_registered?
  end

  def validate_user_allowed_to_watch
    # TODO add informative error message
    return if user.blank? || watchable.blank?
    errors.add :user_id, :invalid unless watchable.possible_watcher?(user)
  end

  class << self
    def prune_project_related(user_ids, projects)
      watchers = watchers_in_projects(projects, user_ids)

      watchers_by_watchable_class = watchers
                                    .includes({ watchable: :project }, :user)
                                    .group_by(&:watchable_type)

      watchers_by_watchable_class.each do |watchable_class_string, class_candidates|
        watchable_class = watchable_class_string.constantize

        destroy_watchers_if_permission_missing(watchable_class, class_candidates)
      end
    end

    def watchers_in_projects(projects, user_ids)
      watchable_classes = active_watchable_classes(user_ids)

      neutral_scope = where(Arel::Nodes::Equality.new(1, 0))

      watchable_classes.inject(neutral_scope) do |aggregate_scope, watched_class|
        klass = watched_class.constantize

        individual_scope = watchers_of_watchable(klass, projects, user_ids)

        aggregate_scope.or(individual_scope)
      end
    end

    def destroy_watchers_if_permission_missing(watchable_class, class_candidates)
      watchers_by_users = class_candidates.group_by(&:user)
      watchers_by_projects = class_candidates.group_by { |c| c.watchable.project }

      if watchers_by_users.keys.length < watchers_by_projects.keys.length
        prune_by_users(watchers_by_users, watchable_class)
      else
        prune_by_projects(watchers_by_projects, watchable_class)
      end
    end

    def prune_by_users(watchers_by_users, watchable_class)
      watchers_by_users.each do |user, watchers|
        allowed_project_ids = Project
                              .allowed_to(user,
                                          watchable_class.acts_as_watchable_permission)
                              .pluck(:id)
        watchers
          .select { |w| !allowed_project_ids.include?(w.watchable.project.id) }
          .each(&:destroy)
      end
    end

    def prune_by_projects(watchers_by_projects, watchable_class)
      watchers_by_projects.each do |project, watchers|
        allowed_user_ids = User
                           .allowed(watchable_class.acts_as_watchable_permission,
                                    project)
                           .pluck(:id)

        watchers
          .select { |c| !allowed_user_ids.include?(c.user_id) }
          .each(&:destroy)
      end
    end

    def watchers_of_watchable(watchable, projects, user_ids)
      # By using
      #   where(projects: { id: project.id }
      # instead of
      #   where(projects_id: project.id)
      # we don't have to distinguish between project associations with
      # project_id on the watchable class and those on a class associated to
      # the watchable class (using :through).
      id_subquery = watchable
                    .joins(:watchers)
                    .joins(:project)
                    .where(projects: { id: projects.map(&:id) })
                    .select('watchers.id')

      id_subquery = id_subquery.where(watchers: { user_id: user_ids }) unless user_ids.empty?

      where(id: id_subquery)
    end

    def active_watchable_classes(user_ids)
      classes = distinct(:watchable_type)
      classes.where(user_id: user_ids) unless user_ids.blank?
      classes.pluck(:watchable_type)
    end
  end
end
