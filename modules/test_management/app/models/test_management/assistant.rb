# frozen_string_literal: true

module TestManagement
  # Test Assistant (0014): Generate (draft test cases from a work package, text, a pull request
  # or code) and Chat (questions about cases, runs, results, milestones and coverage, plus
  # confirmed actions) on one page. Needs the "Use test assistant" permission, the project
  # setting (on by default) and an AI provider configured by an administrator (0021: several
  # saved providers, AssistantProvider; users pick one in the header, ProviderChoice).
  module Assistant
    module_function

    def enabled_for?(project)
      project.present? && project.module_enabled?(:test_management) &&
        TestManagement::ProjectSetting.test_assistant_enabled?(project)
    end

    def allowed?(user, project)
      enabled_for?(project) && user.allowed_in_project?(:use_test_assistant, project)
    end

    # The provider the user works with (0021: picked in the header, else the default) is usable.
    def configured?(user = User.current)
      ProviderChoice.for(user).config.configured?
    end
  end
end
