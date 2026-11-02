# frozen_string_literal: true

module TestManagement
  class TestCase < ApplicationRecord
    self.table_name = "tm_test_cases"

    STATUSES = %w[ready draft deprecated blocked].freeze
    PRIORITIES = %w[critical high medium low].freeze

    belongs_to :project
    belongs_to :suite, class_name: "TestManagement::Suite", optional: true
    belongs_to :author, class_name: "User", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true
    belongs_to :updated_by, class_name: "User", optional: true

    has_many :steps,
             -> { order(:position) },
             class_name: "TestManagement::TestStep",
             foreign_key: :test_case_id,
             dependent: :destroy,
             inverse_of: :test_case

    # Linked work packages (many per case). Links are staged in memory by
    # TestCases::SetAttributesService (build / mark_for_destruction) and persisted
    # on save via autosave, so nothing is written before the contract validated
    # that every newly linked work package is visible to the acting user.
    has_many :test_case_work_packages,
             class_name: "TestManagement::TestCaseWorkPackage",
             inverse_of: :test_case,
             autosave: true,
             # Visibility/existence of linked work packages is validated by the
             # TestCases contracts (single, readable error); skip the generic
             # "Test case work packages is invalid" from associated validation.
             validate: false,
             dependent: :delete_all
    has_many :work_packages, through: :test_case_work_packages

    # Labels (per project). Staged like work package links by the SetAttributesService.
    has_many :test_case_labels,
             class_name: "TestManagement::TestCaseLabel",
             inverse_of: :test_case,
             autosave: true,
             validate: false,
             dependent: :delete_all
    has_many :labels, through: :test_case_labels

    has_many :run_cases,
             class_name: "TestManagement::TestRunCase",
             inverse_of: :test_case,
             dependent: :delete_all
    has_many :test_runs, through: :run_cases

    has_many :events,
             -> { chronological },
             class_name: "TestManagement::TestCaseEvent",
             foreign_key: :test_case_id,
             inverse_of: :test_case,
             dependent: :delete_all

    # --- History (simple audit, see TestCaseEvent) ---------------------------
    # Plain attributes whose old/new values are stored; rich text only as "changed".
    HISTORY_VALUE_ATTRIBUTES = %w[title status priority automated automation_reference suite_id].freeze
    HISTORY_TEXT_ATTRIBUTES = %w[preconditions description].freeze

    before_validation :normalize_automation_reference
    before_save :collect_history_details
    after_save :record_history_event
    # Add the case to active "all" / "dynamic" runs it matches (see TestRuns::AutoAddService).
    # One declaration: after_create_commit + after_update_commit with the same method
    # name would register only the last one.
    after_commit :auto_add_to_test_runs, on: %i[create update]

    # The form always posts a hidden `position`, so `reject_if: :all_blank` would never
    # reject an empty step row. Ignore bookkeeping keys when deciding blankness.
    STEP_CONTENT_KEYS = %w[action expected_result data].freeze

    accepts_nested_attributes_for :steps,
                                  allow_destroy: true,
                                  reject_if: ->(attrs) {
                                    attrs["id"].blank? &&
                                      STEP_CONTENT_KEYS.all? { |key| attrs[key].blank? }
                                  }

    validates :title, presence: true, length: { maximum: 255 }
    validates :status, inclusion: { in: STATUSES }
    validates :priority, inclusion: { in: PRIORITIES }
    validates :automation_reference, length: { maximum: 1024 }
    validate :automation_reference_unique

    scope :not_deleted, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }

    scope :visible, ->(user = User.current) {
      not_deleted
        .includes(:project)
        .references(:projects)
        .merge(Project.allowed_to(user, :view_test_cases))
    }

    scope :in_suite, ->(suite_id) {
      suite_id.present? ? where(suite_id:) : where(suite_id: nil)
    }

    def soft_delete!
      path = suite&.path_name
      update!(
        deleted_at: Time.current,
        deleted_from_suite_id: suite_id,
        deleted_from_suite_path: path
      )
    end

    def restore!(suite_id: :keep)
      attrs = {
        deleted_at: nil,
        deleted_from_suite_id: nil,
        deleted_from_suite_path: nil
      }
      attrs[:suite_id] = suite_id unless suite_id == :keep
      update!(attrs)
    end

    def deleted?
      deleted_at.present?
    end

    # Former folder still exists and can be used for restore without asking.
    def restore_suite
      return if deleted_from_suite_id.blank?

      Suite.find_by(id: deleted_from_suite_id, project_id:)
    end

    def restore_needs_folder?
      deleted? && deleted_from_suite_id.present? && restore_suite.nil?
    end

    def visible?(user = User.current)
      !deleted? && user&.allowed_in_project?(:view_test_cases, project)
    end

    # IDs of work packages linked after the pending (unsaved) link changes are applied.
    def linked_work_package_ids
      test_case_work_packages.reject(&:marked_for_destruction?).map(&:work_package_id)
    end

    def work_package_links_changed?
      test_case_work_packages.any? { |link| link.new_record? || link.marked_for_destruction? }
    end

    # Current label names (after pending, unsaved label changes), for the form field.
    def label_names
      test_case_labels.reject(&:marked_for_destruction?).filter_map { |link| link.label&.name }.join(", ")
    end

    def label_links_changed?
      test_case_labels.any? { |link| link.new_record? || link.marked_for_destruction? }
    end

    def created_event
      events.detect { |event| event.action == "created" }
    end

    def formatted_id
      "##{id}"
    end

    private

    def normalize_automation_reference
      return unless has_attribute?(:automation_reference)

      self.automation_reference = automation_reference.to_s.strip.presence
    end

    def automation_reference_unique
      return if !has_attribute?(:automation_reference) || automation_reference.blank? || deleted?

      clash = self.class.not_deleted
                  .where(project_id:, automation_reference:)
                  .where.not(id:)
                  .exists?
      errors.add(:automation_reference, :taken) if clash
    end

    # Runs before autosave children are written, so pending step / link changes
    # can still be detected.
    def collect_history_details
      @history_details = {}
      return if new_record?

      HISTORY_VALUE_ATTRIBUTES.each do |attr|
        @history_details[attr] = history_value_change(attr) if will_save_change_to_attribute?(attr)
      end
      HISTORY_TEXT_ATTRIBUTES.each do |attr|
        @history_details[attr] = true if will_save_change_to_attribute?(attr)
      end
      @history_details["steps"] = true if steps_pending_changes?
      links = work_package_link_changes
      @history_details["work_packages"] = links if links
      labels = label_changes
      @history_details["labels"] = labels if labels
    end

    def label_changes
      return unless association(:test_case_labels).loaded?

      added = test_case_labels.select { |l| l.new_record? && !l.marked_for_destruction? }.filter_map { |l| l.label&.name }
      removed = test_case_labels.select { |l| l.persisted? && l.marked_for_destruction? }.filter_map { |l| l.label&.name }
      return if added.empty? && removed.empty?

      { "added" => added, "removed" => removed }
    end

    def auto_add_to_test_runs
      return if deleted?

      TestManagement::TestRuns::AutoAddService.new(self).call
    end

    def record_history_event
      if previously_new_record?
        events.create!(action: "created", user_id: author_id)
      elsif @history_details.present?
        events.create!(action: "updated", user_id: updated_by_id || author_id, details: @history_details)
      end
    ensure
      @history_details = nil
    end

    def history_value_change(attr)
      old_value, new_value = attribute_change_to_be_saved(attr)
      if attr == "suite_id"
        [old_value && Suite.find_by(id: old_value)&.name, new_value && Suite.find_by(id: new_value)&.name]
      else
        [old_value, new_value]
      end
    end

    def steps_pending_changes?
      # Nested attributes add to the association target without loading it, so
      # inspect the in-memory target rather than requiring `loaded?`.
      association(:steps).target.any? do |step|
        step.new_record? || step.marked_for_destruction? || step.changed?
      end
    end

    def work_package_link_changes
      return unless association(:test_case_work_packages).loaded?

      added = test_case_work_packages.select { |l| l.new_record? && !l.marked_for_destruction? }.map(&:work_package_id)
      removed = test_case_work_packages.select { |l| l.persisted? && l.marked_for_destruction? }.map(&:work_package_id)
      return if added.empty? && removed.empty?

      { "added" => added, "removed" => removed }
    end
  end
end
