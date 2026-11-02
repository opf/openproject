# frozen_string_literal: true

module TestManagement
  # Per-project label for test cases. `color` is a Primer::Beta::Label scheme.
  class Label < ApplicationRecord
    self.table_name = "tm_labels"

    COLORS = %w[accent success attention severe danger done sponsors secondary].freeze

    belongs_to :project
    has_many :test_case_labels, class_name: "TestManagement::TestCaseLabel", inverse_of: :label, dependent: :delete_all
    has_many :test_cases, through: :test_case_labels

    validates :name, presence: true, length: { maximum: 64 }, uniqueness: { scope: :project_id, case_sensitive: false }
    validates :color, inclusion: { in: COLORS }

    before_validation :assign_default_color, on: :create
    # Labels created through a test case are autosaved with validate: false
    # (belongs_to autosave), which skips before_validation.
    before_create :assign_default_color

    scope :ordered, -> { order(Arel.sql("LOWER(tm_labels.name)")) }

    # Stable color per name so a label keeps its color wherever it is created.
    def self.color_for(name)
      COLORS[name.to_s.downcase.sum % COLORS.size]
    end

    def self.normalize_name(name)
      name.to_s.squish.first(64)
    end

    private

    def assign_default_color
      self.color = self.class.color_for(name) if color.blank?
    end
  end
end
