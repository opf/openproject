# frozen_string_literal: true

module WorkPackages
  class PurgeContract < ::DeleteContract
    delete_permission lambda {
      user.allowed_in_project?(:delete_work_packages, model.project) &&
        user.allowed_in_project?(:view_work_packages_in_trash, model.project)
    }

    validate :enterprise_feature_available
    validate :work_package_is_trashed

    private

    def enterprise_feature_available
      errors.add(:base, I18n.t("work_packages.trash.enterprise_only")) unless WorkPackages::TrashFeature.enabled?
    end

    def work_package_is_trashed
      errors.add(:base, I18n.t("work_packages.trash.not_in_trash")) unless model.trashed?
    end
  end
end
