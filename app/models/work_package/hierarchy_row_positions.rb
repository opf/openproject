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

class WorkPackage::HierarchyRowPositions
  MAX_RESULTS = 10_000

  def initialize(work_packages, user)
    @work_packages = work_packages
    @user = user
  end

  def count
    positions.size
  end

  def entries_for(ids)
    nodes = ids.map(&:to_i)
    return unless nodes.all? { |node| positions.key?(node) }

    nodes.each_with_object({}) { |node, entries| add_with_ancestors(node, entries) }
  end

  private

  attr_reader :work_packages, :user

  def add_with_ancestors(node, entries)
    while node && !entries.key?(node.to_s)
      entries[node.to_s] = { position: positions.fetch(node), parent: parents[node]&.to_s }
      node = parents[node]
    end
  end

  def positions
    tree.first
  end

  def parents
    tree.last
  end

  def tree
    @tree ||= begin
      ranks = work_packages.pluck(:id).each_with_index.to_h
      parents, keys = link_ancestors(ranks)
      [number_depth_first(parents, keys), parents]
    end
  end

  def link_ancestors(ranks)
    parents = {}
    keys = ranks.dup
    visible_ancestor_chains(ranks).each do |id, chain|
      [nil, *chain, id].each_cons(2) { |parent, child| parents[child] = parent }
      chain.each { |ancestor| keys[ancestor] = [keys[ancestor], ranks[id]].compact.min }
    end
    [parents, keys]
  end

  def number_depth_first(parents, keys)
    children = keys.keys.sort_by { |id| keys[id] }.group_by { |id| parents[id] }
    numbered = {}
    stack = children.fetch(nil, []).reverse
    while (id = stack.pop)
      numbered[id] = numbered.size + 1
      stack.concat(children.fetch(id, []).reverse)
    end
    numbered
  end

  def visible_ancestor_chains(ranks)
    return {} if ranks.empty?

    WorkPackageHierarchy
      .joins("INNER JOIN work_packages ancestors ON ancestors.id = work_package_hierarchies.ancestor_id")
      .where(descendant_id: visible_results)
      .where("work_package_hierarchies.generations > 0")
      .where(ancestors: { project_id: Project.allowed_to(user, :view_work_packages) })
      .order(generations: :desc)
      .pluck(:descendant_id, :ancestor_id)
      .group_by(&:first)
      .transform_values { |edges| edges.map(&:last) }
  end

  def visible_results
    WorkPackage.visible(user).where(id: work_packages.unscope(:order).reselect(:id))
  end
end
