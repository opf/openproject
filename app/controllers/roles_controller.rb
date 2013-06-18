#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RolesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def index
    @role_pages, @roles = paginate :roles, :per_page => 25, :order => 'builtin, position'
    render :action => "index", :layout => false if request.xhr?
  end

  def new
    # Prefills the form with 'Non member' role permissions
    @role = Role.new(params[:role] || {:permissions => Role.non_member.permissions})

    @permissions = @role.setable_permissions
    @roles = Role.find :all, :order => 'builtin, position'
  end

  def create
    @role = Role.new(params[:role] || { :permissions => Role.non_member.permissions })
    if @role.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Role.find_by_id(params[:copy_workflow_from]))
        @role.workflows.copy(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      @permissions = @role.setable_permissions
      @roles = Role.find :all, :order => 'builtin, position'

      render :action => 'new'
    end
  end

  def edit
    @role = Role.find(params[:id])
    @permissions = @role.setable_permissions
  end

  def update
    @role = Role.find(params[:id])

    if @role.update_attributes(params[:role])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      @permissions = @role.setable_permissions
      render :action => 'edit'
    end
  end

  def destroy
    @role = Role.find(params[:id])
    @role.destroy
    redirect_to :action => 'index'
  rescue
    flash[:error] =  l(:error_can_not_remove_role)
    redirect_to :action => 'index'
  end

  def report
    @roles = Role.order('builtin, position').all
    @permissions = Redmine::AccessControl.permissions.select { |p| !p.public? }
  end

  def bulk_update
    @roles = Role.order('builtin, position').all

    @roles.each do |role|
      role.permissions = params[:permissions][role.id.to_s]
      role.save
    end

    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'index'
  end
end
