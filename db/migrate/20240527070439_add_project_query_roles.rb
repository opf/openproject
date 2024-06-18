class AddProjectQueryRoles < ActiveRecord::Migration[7.1]
  def up
    view_role ||= ProjectQueryRole.find_or_initialize_by(builtin: Role::BUILTIN_PROJECT_QUERY_VIEW)

    view_role.update!(
      name: I18n.t("seeds.common.project_query_roles.item_0.name", default: "Project query viewer"),
      permissions: %i[
        view_project_query
      ]
    )

    edit_role ||= ProjectQueryRole.find_or_initialize_by(builtin: Role::BUILTIN_PROJECT_QUERY_EDIT)
    edit_role.update!(
      name: I18n.t("seeds.common.project_query_roles.item_1.name", default: "Project query editor"),
      permissions: %i[
        view_project_query
        edit_project_query
      ]
    )
  end
end
