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

module TestManagement
  class Suite < ApplicationRecord
    self.table_name = "tm_suites"

    belongs_to :project
    belongs_to :parent, class_name: "TestManagement::Suite", optional: true
    has_many :children,
             class_name: "TestManagement::Suite",
             foreign_key: :parent_id,
             dependent: :destroy,
             inverse_of: :parent
    has_many :test_cases,
             class_name: "TestManagement::TestCase",
             dependent: :nullify,
             inverse_of: :suite

    validates :name, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { scope: %i[project_id parent_id] }

    scope :ordered, -> { order(:position, :name) }
    scope :roots, -> { where(parent_id: nil) }

    def self.visible(user = User.current)
      includes(:project)
        .references(:projects)
        .merge(Project.allowed_to(user, :view_test_cases))
    end

    def self.subtree_ids(project, ids)
      by_parent = where(project_id: project.id).pluck(:id, :parent_id).group_by(&:last)
      result = Set.new
      queue = Array(ids).map(&:to_i)
      until queue.empty?
        id = queue.shift
        next unless result.add?(id)

        queue.concat(Array(by_parent[id]).map(&:first))
      end
      result.to_a
    end

    def path_name(separator = " / ")
      names = []
      node = self
      seen = []
      while node && seen.exclude?(node.id)
        seen << node.id
        names.unshift(node.name)
        node = node.parent
      end
      names.join(separator)
    end
  end
end
