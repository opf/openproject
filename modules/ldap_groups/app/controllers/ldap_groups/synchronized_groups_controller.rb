module LdapGroups
  class SynchronizedGroupsController < ::ApplicationController
    before_action :require_admin
    before_action :check_ee
    before_action :find_group, only: %i(show destroy_info destroy)

    layout 'admin'
    menu_item :plugin_ldap_groups
    include PaginationHelper

    def index
      @groups = SynchronizedGroup.includes(:auth_source, :group)
      @filters = SynchronizedFilter.includes(:auth_source, :groups)
    end

    def new
      @group = SynchronizedGroup.new
    end

    def show
      render
    end

    def create
      @group = SynchronizedGroup.new permitted_params

      if @group.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to action: :index
      else
        render action: :new
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def destroy_info
      render
    end

    def destroy
      if @group.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to action: :index
    end

    private

    def find_group
      @group = SynchronizedGroup.find(params[:ldap_group_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def check_ee
      unless EnterpriseToken.allows_to?(:ldap_groups)
        render template: 'ldap_groups/synchronized_groups/upsale'
        return false
      end
    end

    def permitted_params
      params
        .require(:synchronized_group)
        .permit(:dn, :group_id, :auth_source_id)
    end

    def default_breadcrumb
      if action_name == 'index'
        t('ldap_groups.synchronized_groups.plural')
      else
        ActionController::Base.helpers.link_to(t('ldap_groups.synchronized_groups.plural'), ldap_groups_synchronized_groups_path)
      end
    end

    def show_local_breadcrumb
      true
    end
  end
end
