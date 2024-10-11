class AddStandardGlobalRole < ActiveRecord::Migration[7.1]
  def change
    standard_global_role ||= GlobalRole.find_or_initialize_by(builtin: Role::BUILTIN_STANDARD_GLOBAL)

    standard_global_role.update!(
      name: I18n.t("seeds.common.global_roles.item_1.name", default: "Standard global role"),
      permissions: %i[
        view_user_email
      ]
    )
  end
end
