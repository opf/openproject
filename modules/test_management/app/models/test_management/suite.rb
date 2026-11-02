# frozen_string_literal: true

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

    # IDs of the given folders and all their descendants (within one project).
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

    # "Parent / Child / Grandchild"
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

    def cases_count
      test_cases.not_deleted.count
    end

    def recursive_cases_count
      cases_count + children.sum(&:recursive_cases_count)
    end
  end
end
