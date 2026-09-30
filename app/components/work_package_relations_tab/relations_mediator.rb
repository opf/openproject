# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackageRelationsTab::RelationsMediator
  RelationGroup = Data.define(:type, :work_package, :visible_relations, :ghost_relations, :closest_relation) do
    def initialize(type:, work_package:, visible_relations:, ghost_relations:)
      type = ActiveSupport::StringInquirer.new(type.to_s)
      closest_relation = WorkPackageRelationsTab::ClosestRelation.of(work_package, visible_relations + ghost_relations)
      super(type:, work_package:, visible_relations:, ghost_relations:, closest_relation:)
    end

    def count
      [visible_relations, ghost_relations].sum(&:count)
    end

    def any?
      visible_relations.any? || ghost_relations.any?
    end

    def all_relation_items
      (visible_relation_items + ghost_relation_items).sort_by(&:order_key)
    end

    def visible_relation_items
      to_relation_items(visible_relations, :visible)
    end

    def ghost_relation_items
      to_relation_items(ghost_relations, :ghost)
    end

    def closest_relation?(relation) = closest_relation == relation

    def to_relation_items(relations, visibility)
      relations.map do |relation|
        closest = closest_relation?(relation)
        RelationItem.new(type:, work_package:, relation:, visibility:, closest:)
      end
    end
  end

  # Represents a relation item to be displayed in the relations tab or the date
  # picker tabs.
  #
  # @param type [String] The type of relation
  # @param work_package [WorkPackage] The work package for which the relation
  #   is displayed
  # @param related [WorkPackage] The related work package: the other work
  #   package of the relation, or the child for child relations.
  # @param relation [Relation, nil] The relation, `nil` for child relations
  # @param visibility [Symbol] The visibility of the relation, `:visible` to
  #   show related work package information or `:ghost` to show a placeholder
  #   with dates and lag information for some relation types
  # @param closest [Boolean] Whether the relation is the closest follows
  #   relation
  RelationItem = Data.define(:type, :work_package, :related, :relation, :visibility, :closest) do
    def initialize(type:, work_package:, relation:, visibility: :visible, closest: false)
      type = ActiveSupport::StringInquirer.new(type.to_s)
      if relation.is_a?(Relation)
        related = relation.other_work_package(work_package)
      else
        related = relation # for parent-child relations, `relation` parameter holds the child or parent work package
        relation = nil
      end
      super(type:, work_package:, related:, relation:, visibility:, closest:)
    end

    def visible? = visibility == :visible

    def closest? = closest

    def order_key
      [type, relation&.id, related&.id]
    end
  end

  attr_reader :work_package

  def initialize(work_package:)
    @work_package = work_package
  end

  def visible_relations
    @visible_relations ||= work_package.relations.visible.includes(:to, :from).load
  end

  def visible_parents
    @visible_parents ||= work_package.parent_id && work_package.parent.visible? ? [work_package.parent] : []
  end

  def visible_children
    @visible_children ||= work_package.children.visible.load
  end

  def ghost_relations
    @ghost_relations ||= work_package.relations.includes(:to, :from).where.not(id: visible_relations.select(:id)).load
  end

  def ghost_parents
    @ghost_parents ||= work_package.parent_id && !work_package.parent.visible? ? [work_package.parent] : []
  end

  def ghost_children
    @ghost_children ||= work_package.children.where.not(id: visible_children.select(:id)).load
  end

  def relation_groups
    @relation_groups ||= Relation::ORDERED_TYPES.map { |type| relation_group(type) }
                                                .filter(&:any?)
  end

  def relation_group(type)
    case type
    when Relation::TYPE_PARENT
      RelationGroup.new(
        type:,
        work_package:,
        visible_relations: visible_parents,
        ghost_relations: ghost_parents
      )
    when Relation::TYPE_CHILD
      RelationGroup.new(
        type:,
        work_package:,
        visible_relations: visible_children,
        ghost_relations: ghost_children
      )
    else
      RelationGroup.new(
        type:,
        work_package:,
        visible_relations: filter_relations_by_type(visible_relations, type),
        ghost_relations: filter_relations_by_type(ghost_relations, type)
      )
    end
  end

  def all_relations_count
    [
      visible_relations, ghost_relations,
      visible_parents, ghost_parents,
      visible_children, ghost_children
    ].sum(&:count)
  end

  private

  def filter_relations_by_type(relations, type)
    relations.select do |relation|
      relation.relation_type_for(work_package) == type
    end
  end
end
