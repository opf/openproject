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
  class TestRun < ApplicationRecord
    self.table_name = "tm_test_runs"

    STATES = %w[new in_progress completed cancelled].freeze
    ACTIVE_STATES = %w[new in_progress].freeze
    FINISHED_STATES = %w[completed cancelled].freeze
    SELECTION_MODES = %w[all specific].freeze
    SOURCES = %w[manual automation].freeze
    AUTOMATION_FILTERS = %w[any automated manual].freeze

    belongs_to :project
    belongs_to :author, class_name: "User", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true
    belongs_to :finished_by, class_name: "User", optional: true
    belongs_to :connection, class_name: "TestManagement::CiConnection", optional: true, inverse_of: :test_runs

    has_many :run_cases,
             class_name: "TestManagement::TestRunCase",
             inverse_of: :test_run,
             dependent: :delete_all
    has_many :test_cases, through: :run_cases

    has_many :automation_imports,
             class_name: "TestManagement::AutomationImport",
             inverse_of: :test_run,
             dependent: :delete_all

    has_many :iterations,
             -> { order(:number) },
             class_name: "TestManagement::TestRunIteration",
             foreign_key: :test_run_id,
             inverse_of: :test_run,
             dependent: :delete_all

    # nil means "not submitted, keep the current cases".
    attr_accessor :selected_case_ids

    validates :name, presence: true, length: { maximum: 255 }
    validates :state, inclusion: { in: STATES }
    validates :selection_mode, inclusion: { in: SELECTION_MODES }
    validates :source, inclusion: { in: SOURCES }
    validates :completion_source, inclusion: { in: SOURCES }, allow_nil: true
    validates :external_ref, length: { maximum: 255 }, uniqueness: { scope: :project_id }, allow_nil: true
    validate :end_date_after_start_date

    scope :active, -> { where(state: ACTIVE_STATES) }
    scope :in_state, ->(state) { where(state:) }
    scope :newest_first, -> { order(id: :desc) }

    def active?
      ACTIVE_STATES.include?(state)
    end

    def finished?
      FINISHED_STATES.include?(state)
    end
    alias_method :frozen_statuses?, :finished?

    def auto_adds_cases?
      active? && selection_mode == "all"
    end

    def formatted_id
      "R#{id}"
    end

    def automation?
      source == "automation"
    end

    def ci_info
      (ci_metadata || {}).stringify_keys
    end

    def unmatched_tests
      automation_imports.order(:id).flat_map(&:unmatched_list)
    end

    def filter_suite_ids
      Array(filter_options&.dig("suite_ids")).map(&:to_i).reject(&:zero?)
    end

    def filter_automation
      value = filter_options&.dig("automation").to_s
      AUTOMATION_FILTERS.include?(value) ? value : "any"
    end

    def matching_cases_scope
      return project.tm_test_cases.none unless selection_mode == "all"

      scope = project.tm_test_cases
      scope = scope.where(automated: filter_automation == "automated") unless filter_automation == "any"
      scope = scope.where(suite_id: Suite.subtree_ids(project, filter_suite_ids)) if filter_suite_ids.any?
      scope
    end

    def matches?(test_case)
      test_case.project_id == project_id && matching_cases_scope.exists?(id: test_case.id)
    end

    def add_cases!(cases = nil)
      cases ||= matching_cases_scope
      existing = run_cases.pluck(:test_case_id)
      Array(cases.is_a?(ActiveRecord::Relation) ? cases.to_a : cases).each do |test_case|
        next if existing.include?(test_case.id)

        run_cases.create!(test_case:, assigned_to_id:, status: "untested")
        existing << test_case.id
      end
    end

    def current_iteration
      iterations.reorder(number: :desc).first
    end

    def current_iteration_number
      return @preloaded_stats[:current_iteration_number] if @preloaded_stats

      iterations.maximum(:number)
    end

    def iterations_count
      return @preloaded_stats[:iterations_count] if @preloaded_stats

      iterations.count
    end

    def iteration(number)
      iterations.find_by(number: number.to_i)
    end

    def status_counts
      return @preloaded_stats[:status_counts] if @preloaded_stats

      counts = run_cases.group(TestRunCase.effective_status_sql).count
      TestRunCase::STATUSES.index_with { |status| counts[status].to_i }
    end

    def unmatched_tests_count
      return @preloaded_stats[:unmatched_tests_count] if @preloaded_stats

      automation_imports.sum(:unmatched_count)
    end

    def self.preload_stats(runs) # rubocop:disable Metrics/AbcSize
      runs = runs.to_a
      ids = runs.map(&:id)
      return runs if ids.empty?

      counts = TestRunCase.where(test_run_id: ids).group(:test_run_id, TestRunCase.effective_status_sql).count
      iterations = TestRunIteration.where(test_run_id: ids).group(:test_run_id)
                                   .pluck(:test_run_id, Arel.sql("MAX(number)"), Arel.sql("COUNT(*)"))
                                   .to_h { |id, max, count| [id, [max, count]] }
      unmatched = AutomationImport.where(test_run_id: ids).group(:test_run_id).sum(:unmatched_count)
      ActiveRecord::Associations::Preloader.new(records: runs, associations: :connection).call
      runs.each do |run|
        run.preloaded_stats = {
          status_counts: TestRunCase::STATUSES.index_with { |status| counts[[run.id, status]].to_i },
          current_iteration_number: iterations.dig(run.id, 0),
          iterations_count: iterations.dig(run.id, 1).to_i,
          unmatched_tests_count: unmatched[run.id].to_i
        }
      end
    end

    attr_writer :preloaded_stats

    def reload(*)
      @preloaded_stats = nil
      super
    end

    def total_cases
      status_counts.values.sum
    end

    def passed_percent(counts = status_counts)
      self.class.pass_rate(counts)
    end

    def self.pass_rate(counts)
      total = counts.values.sum - counts["skipped"].to_i
      return 0 if total <= 0

      ((counts["passed"].to_f / total) * 100).round
    end

    private

    def end_date_after_start_date
      return if start_date.blank? || end_date.blank? || end_date >= start_date

      errors.add :end_date, :greater_than_or_equal_to, count: I18n.l(start_date)
    end
  end
end
