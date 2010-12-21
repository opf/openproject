class PrincipalRolesController < ApplicationController
  unloadable (PrincipalRolesController)

  def create
    principal_roles = create_principal_roles_from_params

    respond_to do |format|
      format.js do
        render(:update) do |page|
          principal_roles.each do |role|
            page.remove "principal_role_option_#{role.role.id}"
            page.insert_html :top, 'table_principal_roles_body',
                             :partial => "principal_roles/show_table_row",
                             :locals => {:principal_role => role}
          end
        end
      end
    end
  end

  def destroy
    principal_role = PrincipalRole.find(params[:id])
    principal_role.destroy

    respond_to do |format|
      format.js do
        render(:update) do |page|
          page.remove "principal_role_#{params[:id]}"
        end
      end
    end
  end

  private

  def create_principal_roles_from_params
    role_ids = params[:principal_role][:role_id] ? [params[:principal_role].delete(:role_id)] : params[:principal_role].delete(:role_ids)
    roles = Role.find role_ids
    principal_roles = []
    role_ids.each do |role_id|
      role = PrincipalRole.new(params[:principal_role])
      role.role = roles.detect {|r| r.id == role_id.to_i}
      role.save
      principal_roles << role
    end
    principal_roles
  end
end