# frozen_string_literal: true

module TestManagement
  class ProjectSetting < ApplicationRecord
    self.table_name = "tm_project_settings"

    FOLDER_TREE_LAYOUTS = %w[split_pane sidebar].freeze
    DEFAULT_FOLDER_TREE_LAYOUT = "split_pane"

    belongs_to :project

    validates :project_id, uniqueness: true
    validate :validate_folder_tree_layout

    store_accessor :options, :folder_tree_layout, :enable_ci, :enable_milestones, :enable_test_plans,
                   :enable_test_assistant

    before_validation :normalize_blank_folder_tree_layout

    def self.for_project(project)
      find_or_initialize_by(project:)
    end

    def self.folder_tree_layout_for(project)
      for_project(project).effective_folder_tree_layout
    end

    # Milestones (0012) are on unless switched off in Project settings > Test management.
    def milestones_enabled?
      !ActiveModel::Type::Boolean.new.cast(enable_milestones).equal?(false)
    end

    def self.milestones_enabled?(project)
      return false if project.nil?

      setting = find_by(project_id: project.id)
      setting.nil? || setting.milestones_enabled?
    end

    # Test plans are on unless switched off. Configurations stay available either way.
    def plans_enabled?
      !ActiveModel::Type::Boolean.new.cast(enable_test_plans).equal?(false)
    end

    def self.plans_enabled?(project)
      return false if project.nil?

      setting = find_by(project_id: project.id)
      setting.nil? || setting.plans_enabled?
    end

    # The Test Assistant (0014) is on unless switched off in Project settings > Test management.
    def test_assistant_enabled?
      !ActiveModel::Type::Boolean.new.cast(enable_test_assistant).equal?(false)
    end

    def self.test_assistant_enabled?(project)
      return false if project.nil?

      setting = find_by(project_id: project.id)
      setting.nil? || setting.test_assistant_enabled?
    end

    # Projects with milestones switched off (few rows; the JSON flag is read in Ruby so
    # this works for any JSON representation of false).
    def self.milestones_disabled_project_ids
      where("options ->> 'enable_milestones' IS NOT NULL").select(:project_id,
                                                                  :options).reject(&:milestones_enabled?).map(&:project_id)
    end

    def self.plans_disabled_project_ids
      where("options ->> 'enable_test_plans' IS NOT NULL").select(:project_id,
                                                                  :options).reject(&:plans_enabled?).map(&:project_id)
    end

    def effective_folder_tree_layout
      layout = folder_tree_layout.presence || DEFAULT_FOLDER_TREE_LAYOUT
      FOLDER_TREE_LAYOUTS.include?(layout) ? layout : DEFAULT_FOLDER_TREE_LAYOUT
    end

    def split_pane_layout?
      effective_folder_tree_layout == "split_pane"
    end

    def sidebar_layout?
      effective_folder_tree_layout == "sidebar"
    end

    private

    def normalize_blank_folder_tree_layout
      self.folder_tree_layout = DEFAULT_FOLDER_TREE_LAYOUT if folder_tree_layout.blank?
    end

    def validate_folder_tree_layout
      return if FOLDER_TREE_LAYOUTS.include?(folder_tree_layout.to_s)

      errors.add(:folder_tree_layout, :inclusion)
    end
  end
end
