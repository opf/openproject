class PrincipalRolesController < ApplicationController
  unloadable (PrincipalRolesController)

  #before_filter :authorize

  def create
    @principal_roles = new_principal_roles_from_params

    call_hook :principal_roles_controller_create_before_save,
              {:principal_roles => @principal_roles}

    @principal_roles.each{ |pr| pr.save } unless performed?

    call_hook :principal_roles_controller_create_before_respond,
              {:principal_roles => @principal_roles}

    respond_to_create @principal_roles unless performed?
  end

  def update
    @principal_role = PrincipalRole.find(params[:principal_role][:id])

    call_hook :principal_roles_controller_update_before_save,
              {:principal_role => @principal_role}

    @principal_role.update_attributes(params[:principal_role]) unless performed?

    call_hook :principal_roles_controller_update_before_respond,
              {:principal_role => @principal_role}

    respond_to_update @principal_role unless performed?
  end

  def destroy
    @principal_role = PrincipalRole.find(params[:id])
    @user = Principal.find(@principal_role.principal_id)
    @global_roles = GlobalRole.all

    call_hook :principal_roles_controller_destroy_before_destroy,
              {:principal_role => @principal_role}

    @principal_role.destroy

    call_hook :principal_roles_controller_update_before_respond,
              {:principal_role => @principal_role}

    respond_to_destroy @principal_role, @user, @global_roles
  end

  private

  def new_principal_roles_from_params
    pr_params = params[:principal_role].dup
    role_ids = pr_params[:role_id] ? [pr_params.delete(:role_id)] : pr_params.delete(:role_ids)
    roles = Role.find role_ids
    principal_roles = []
    role_ids.map(&:to_i).each do |role_id|
      role = PrincipalRole.new(pr_params)
      role.role = roles.detect {|r| r.id == role_id}
      principal_roles << role
    end
    principal_roles
  end

  def respond_to_create roles
    respond_to do |format|
      format.js do
        render(:update) do |page|
          roles.each do |role|
            page.remove "principal_role_option_#{role.role_id}"
            page.insert_html :top, 'table_principal_roles_body',
                             :partial => "principal_roles/show_table_row",
                             :locals => {:principal_role => role}

            call_hook :principal_roles_controller_create_respond_js_role,
                      {:page => page, :principal_role => role}
          end
        end
      end
    end
  end

  def respond_to_update role
    respond_to do |format|
      format.js do
        render(:update) do |page|
          if role.valid?
            page.replace "principal_role-#{role.id}",
                          :partial => "principal_roles/show_table_row",
                          :locals => {:principal_role => role}
          else
            page.insert_html :top, "tab-content-global_roles", :partial => 'errors'
          end

          call_hook :principal_roles_controller_update_respond_js_role,
                    {:page => page, :principal_role => role}
        end
      end
    end
  end

  def respond_to_destroy principal_role, user, global_roles
    respond_to do |format|
      format.js do
        render(:update) do |page|
          page.remove "principal_role-#{principal_role.id}"
          page.replace "available_principal_roles",
                        :partial => "users/available_global_roles",
                        :locals => {:user => user, :global_roles => global_roles}

          call_hook :principal_roles_controller_update_respond_js_role,
                        {:page => page, :principal_role => principal_role}
        end
      end
    end
  end
end