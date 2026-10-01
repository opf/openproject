# frozen_string_literal: true

module LdapDepartments
  class SynchronizedTreesController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[index show deletion_dialog destroy]) do
      redirect_to action: :index, status: :see_other
    end

    before_action :find_tree, only: %i[show edit update destroy deletion_dialog synchronize]

    layout "admin"
    menu_item :plugin_ldap_departments

    def index
      @trees = SynchronizedTree.includes(:ldap_auth_source, :synchronized_departments)
    end

    def show
      @departments = @tree.synchronized_departments.includes(group: :group_detail)
    end

    def new
      @tree = SynchronizedTree.new
    end

    def edit; end

    def create
      @tree = SynchronizedTree.new(permitted_params)

      if @tree.save
        SynchronizeTreeJob.perform_later(@tree)
        flash[:notice] = I18n.t("ldap_departments.synchronized_trees.synchronization_started")
        redirect_to action: :show, tree_id: @tree.id
      else
        render action: :new, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def update
      if @tree.update(permitted_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :show
      else
        render action: :edit, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def deletion_dialog
      respond_with_dialog SynchronizedTrees::DeleteDialogComponent.new(tree: @tree)
    end

    def destroy
      if @tree.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to action: :index, status: :see_other
    end

    def synchronize
      SynchronizeTreeJob.perform_later(@tree)
      flash[:notice] = I18n.t("ldap_departments.synchronized_trees.synchronization_started")
      redirect_to action: :show
    end

    private

    def find_tree
      @tree = SynchronizedTree.find(params.expect(:tree_id))
    end

    def permitted_params
      params.expect(synchronized_tree: %i[name
                                          base_dn
                                          ldap_auth_source_id
                                          structure_filter_string
                                          ou_name_attribute
                                          guid_attribute
                                          user_filter_string
                                          sync_users])
    end
  end
end
