# frozen_string_literal: true

module WorkPackages
  class TrashContract < ::DeleteContract
    delete_permission :manage_work_package_trash

    validate :enterprise_feature_available
    validate :work_package_is_active

    private

    def enterprise_feature_available
      errors.add(:base, I18n.t("work_packages.trash.enterprise_only")) unless WorkPackages::TrashFeature.enabled?
    end

    def work_package_is_active
      errors.add(:base, I18n.t("work_packages.trash.already_in_trash")) if model.trashed?
    end
  end
end
