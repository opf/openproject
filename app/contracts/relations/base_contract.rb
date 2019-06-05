#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'model_contract'

module Relations
  class BaseContract < ::ModelContract
    attribute :relation_type
    attribute :delay
    attribute :description
    attribute :from
    attribute :to

    validate :manage_relations_permission?
    validate :validate_from_exists
    validate :validate_to_exists
    validate :validate_only_one_follow_direction_between_hierarchies
    validate :validate_accepted_type

    def self.model
      Relation
    end

    def validate!(*args)
      # same as before_validation callback
      model.send(:reverse_if_needed)
      super
    end

    private

    def validate_from_exists
      errors.add :from, :error_not_found unless visible_work_packages.exists? model.from_id
    end

    def validate_to_exists
      errors.add :to, :error_not_found unless visible_work_packages.exists? model.to_id
    end

    def validate_only_one_follow_direction_between_hierarchies
      return unless [Relation::TYPE_HIERARCHY, Relation::TYPE_FOLLOWS].include? model.relation_type

      if follow_relations_in_opposite_direction.exists?
        errors.add :base, I18n.t(:'activerecord.errors.messages.circular_dependency')
      end
    end

    def validate_accepted_type
      return if (Relation::TYPES.keys + [Relation::TYPE_HIERARCHY]).include?(model.relation_type)

      errors.add :relation_type, :inclusion
    end

    def manage_relations_permission?
      if !manage_relations?
        errors.add :base, :error_unauthorized
      end
    end

    def visible_work_packages
      ::WorkPackage.visible(user)
    end

    def manage_relations?
      user.allowed_to? :manage_work_package_relations, model.from.project
    end

    # Go up to's hierarchy to the highest ancestor not shared with from.
    # Fetch all endpoints of relations that are reachable by following at least one follows
    # and zero or more hierarchy relations.
    # We now need to check whether those endpoints include any that
    #
    # * are an ancestor of from
    # * are a descendant of from
    # * are from itself
    #
    # Siblings and sibling subtrees of ancestors are ok to have relations
    def follow_relations_in_opposite_direction
      to_set = hierarchy_or_follows_of

      follows_relations_to_ancestors(to_set)
        .or(follows_relations_to_descendants(to_set))
        .or(follows_relations_to_from(to_set))
    end

    def hierarchy_or_follows_of
      to_root_ancestor = tos_highest_ancestor_not_shared_by_from

      Relation
        .hierarchy_or_follows
        .where(from_id: to_root_ancestor)
        .where('follows > 0')
    end

    def tos_highest_ancestor_not_shared_by_from
      # mysql does not support a limit inside a subquery.
      # we thus join/subselect the query for ancestors of to not shared by from
      # with itself and exclude all that have a hierarchy value smaller than hierarchy - 1
      unshared_ancestors = tos_ancestors_not_shared_by_from

      unshared_ancestors
        .where.not(hierarchy: unshared_ancestors.select('hierarchy - 1'))
        .select(:from_id)
    end

    def tos_ancestors_not_shared_by_from
      Relation
        .hierarchy_or_reflexive
        .where(to_id: model.to_id)
        .where.not(from_id: Relation.hierarchy_or_reflexive
                              .where(to_id: model.from_id)
                              .select(:from_id))
    end

    def follows_relations_to_ancestors(to_set)
      ancestors = Relation.hierarchy.where(to_id: model.from)
      to_set.where(to_id: ancestors.select(:from_id))
    end

    def follows_relations_to_descendants(to_set)
      descendants = Relation.hierarchy.where(from_id: model.from)
      to_set.where(to_id: descendants.select(:to_id))
    end

    def follows_relations_to_from(to_set)
      to_set.where(to_id: model.from_id)
    end
  end
end
