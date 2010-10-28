class GlobalRolesController < ApplicationController
  unloadable (GlobalRolesController)

  def new
    @role = GlobalRole.new
    @giveable_permissions = Redmine::AccessControl.permissions
  end

  def create
    @role = GlobalRole.new params[:role]
    @role.save
    @giveable_permissions = Redmine::AccessControl.permissions
  end

  def edit
    @role = GlobalRole.find params[:id]
    @giveable_permissions = Redmine::AccessControl.permissions
  end

  def update
    @role = GlobalRole.find params[:role][:id]
    @role.attributes = params[:role]
    @role.save
    @giveable_permissions = Redmine::AccessControl.permissions
  end

  def show
    @role = GlobalRole.find params[:id]
    @giveable_permissions = Redmine::AccessControl.permissions
  end

  def destroy
    @role = GlobalRole.find params[:id]
    @role.destroy
  end

  def index
    @roles = GlobalRole.all
  end


end