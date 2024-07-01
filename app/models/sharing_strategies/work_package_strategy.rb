module SharingStrategies
  class WorkPackageStrategy
    attr_reader :work_package

    def initialize(work_package:)
      @work_package = work_package
    end

    def available_roles
      role_mapping = WorkPackageRole.unscoped.pluck(:builtin, :id).to_h

      [
        { label: I18n.t("work_package.permissions.edit"),
          value: role_mapping[Role::BUILTIN_WORK_PACKAGE_EDITOR],
          description: I18n.t("work_package.permissions.edit_description") },
        { label: I18n.t("work_package.permissions.comment"),
          value: role_mapping[Role::BUILTIN_WORK_PACKAGE_COMMENTER],
          description: I18n.t("work_package.permissions.comment_description") },
        { label: I18n.t("work_package.permissions.view"),
          value: role_mapping[Role::BUILTIN_WORK_PACKAGE_VIEWER],
          description: I18n.t("work_package.permissions.view_description"),
          default: true }
      ]
    end

    def sharing_manageable?
      User.current.allowed_in_project?(:share_work_packages, @work_package.project)
    end

    def create_contract_class
      Shares::WorkPackages::CreateContract
    end

    def update_contract_class
      Shares::WorkPackages::UpdateContract
    end

    def delete_contract_class
      Shares::WorkPackages::DeleteContract
    end
  end
end
