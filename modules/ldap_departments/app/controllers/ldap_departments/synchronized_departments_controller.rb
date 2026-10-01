# frozen_string_literal: true

module LdapDepartments
  class SynchronizedDepartmentsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[deletion_dialog destroy]) do
      redirect_to ldap_departments_synchronized_trees_path, status: :see_other
    end

    before_action :find_department, only: %i[deletion_dialog destroy]

    layout "admin"
    menu_item :plugin_ldap_departments

    def deletion_dialog
      respond_with_dialog SynchronizedDepartments::DeleteDialogComponent.new(department: @department)
    end

    # Removing the mapping unmanages the department (it and externally-added members are kept).
    def destroy
      tree_id = @department.synchronized_tree_id

      if @department.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to ldap_departments_synchronized_tree_path(tree_id:), status: :see_other
    end

    private

    def find_department
      @department = SynchronizedDepartment.find(params.expect(:department_id))
    end
  end
end
