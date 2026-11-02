# frozen_string_literal: true

module TestManagement
  module Automation
    # autoCreateCases: creates an automated case for an unmatched record, filed in
    # "<target folder>/Automated/<spec file>" with the record's reference, and the
    # report's tags (minus case-id tags) plus the `labels` option as labels. The reference is
    # repo-qualified ("shop:…", "shop/e2e:…") when the upload's repository is known (0016).
    class CaseCreator
      ROOT_FOLDER = "Automated"

      def initialize(user:, project:, options:, references: nil)
        @user = user
        @project = project
        @options = options
        @references = references
        @folders = {}
      end

      def call(record)
        test_case = project.tm_test_cases.create!(
          title: record.display_title.to_s.first(255),
          suite: folder_for(record.file),
          automated: true,
          automation_reference: reference_for(record),
          author: user,
          status: "ready",
          priority: "medium"
        )
        add_labels(test_case, record)
        test_case
      end

      private

      attr_reader :user, :project, :options, :references

      # Repo-qualified when the upload's repository is known (0016).
      def reference_for(record)
        return nil if record.reference.blank?

        (references ? references.reference_for(record) : record.reference).first(1024)
      end

      def folder_for(file)
        @folders[file] ||= begin
          parent = options.target_suite_id && project.tm_suites.find_by(id: options.target_suite_id)
          parent = find_or_create_folder(ROOT_FOLDER, parent)
          file.present? ? find_or_create_folder(file.to_s.first(255), parent) : parent
        end
      end

      def find_or_create_folder(name, parent)
        project.tm_suites.find_or_create_by!(name:, parent_id: parent&.id)
      end

      def add_labels(test_case, record)
        names = (record.tags.map { |tag| tag.delete_prefix("@") }.grep_v(/\A[A-Za-z]{1,10}-?\d+\z/) +
                 options.labels).map { |n| TestManagement::Label.normalize_name(n) }.compact_blank.uniq(&:downcase)
        return if names.empty?

        downcased_names = names.map(&:downcase)
        labels_by_downcase = TestManagement::Label.where(project_id: project.id)
                                                  .where("LOWER(name) IN (?)", downcased_names)
                                                  .index_by { |label| label.name.downcase }

        names.each do |name|
          downcased_name = name.downcase
          label = labels_by_downcase[downcased_name] ||
                  TestManagement::Label.create!(project_id: project.id, name:).tap do |created|
                    labels_by_downcase[downcased_name] = created
                  end
          TestManagement::TestCaseLabel.find_or_create_by!(test_case_id: test_case.id, label_id: label.id)
        end
      end
    end
  end
end
