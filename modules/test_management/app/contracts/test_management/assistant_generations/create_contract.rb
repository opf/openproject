# frozen_string_literal: true

module TestManagement
  module AssistantGenerations
    # Who may ask the Test Assistant to generate drafts, and what a valid request looks like.
    # Saving drafts is checked separately (TestCases::CreateContract, i.e. "Add test cases").
    class CreateContract < ::ModelContract
      MAX_PENDING_PER_USER = 3
      MAX_LABELS = 20

      def self.model
        TestManagement::AssistantGeneration
      end

      attribute :project
      attribute :user
      attribute :source_type
      attribute :source
      attribute :options
      attribute :status
      attribute :progress_step
      attribute :provider_id # 0021: the picked provider and model (ProviderChoice)
      attribute :chosen_model

      validate :user_allowed
      validate :assistant_enabled
      validate :provider_configured
      validate :source_valid
      validate :options_valid
      validate :not_too_many_pending

      private

      def user_allowed
        return if model.project.nil?
        return if model.user == user && user.allowed_in_project?(:use_test_assistant, model.project)

        errors.add :base, :error_unauthorized
      end

      def assistant_enabled
        return if model.project.nil? || TestManagement::Assistant.enabled_for?(model.project)

        errors.add :base, :tm_assistant_disabled
      end

      def provider_configured
        errors.add :base, :tm_assistant_not_configured unless TestManagement::Assistant.configured?(model.user || user)
      end

      def source_valid
        data = model.source_data
        case model.source_type
        when "work_package"
          wp = TestManagement::Assistant::Sources::WorkPackage.new(user:, work_package_id: data["work_package_id"]).work_package
          errors.add :source, :tm_work_package_not_found unless wp
        when "text" then text_valid(data["text"])
        when "code" then text_valid(data["code"])
        when "pull_request"
          matched = model.project && TestManagement::Assistant::Sources::PullRequest.new(project: model.project,
                                                                                         url: data["url"]).match
          errors.add :source, :tm_pull_request_unknown unless matched
        end
      end

      def text_valid(value)
        if value.to_s.strip.empty?
          errors.add :source, :blank
        elsif value.to_s.length > TestManagement::Assistant::Sources::MAX_TEXT_CHARS
          errors.add :source, :too_long, count: TestManagement::Assistant::Sources::MAX_TEXT_CHARS
        end
      end

      def options_valid
        count = model.option(:count)
        unless count.to_s.match?(/\A\d+\z/) && count.to_i.between?(1, TestManagement::AssistantGeneration::MAX_COUNT)
          errors.add :options, :tm_assistant_count, max: TestManagement::AssistantGeneration::MAX_COUNT
        end
        types = Array(model.option(:types)).map(&:to_s)
        if types.empty? || (types - TestManagement::AssistantGeneration::CASE_TYPES).any?
          errors.add :options, :tm_assistant_types
        end
        suite_id = model.option(:suite_id)
        if suite_id.present? && !TestManagement::Suite.exists?(id: suite_id.to_i, project_id: model.project&.id)
          errors.add :options, :tm_assistant_folder
        end
        labels = Array(model.option(:label_names))
        errors.add :options, :tm_assistant_labels if labels.size > MAX_LABELS || labels.any? { |l| l.to_s.length > 255 }
      end

      def not_too_many_pending
        return if model.project.nil? || user.nil?

        pending = TestManagement::AssistantGeneration.of(user, model.project).where(status: %w[queued running])
                    .where("updated_at > ?", TestManagement::AssistantGeneration::STALE_AFTER.ago).count
        errors.add :base, :tm_assistant_busy if pending >= MAX_PENDING_PER_USER
      end
    end
  end
end
