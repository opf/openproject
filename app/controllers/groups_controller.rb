#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class GroupsController < ApplicationController
  layout 'admin'

  before_filter :require_admin


  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.find(:all, :order => 'lastname')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id], :include => :projects)
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to(groups_path) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(groups_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

  def add_users
    @group = Group.find(params[:id])
    users = User.find_all_by_id(params[:user_ids])
    @group.users << users if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'users' }
      format.js {
        render(:update) {|page|
          page.replace_html "tab-content-users", :partial => 'groups/users'
          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
        }
      }
    end
  end

  def remove_user
    @group = Group.find(params[:id])
    @group.users.delete(User.find(params[:user_id])) if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'users' }
      format.js { render(:update) {|page| page.replace_html "tab-content-users", :partial => 'groups/users'} }
    end
  end

  def edit_membership
    @group = Group.find(params[:id])

    if params[:project_ids] # Multiple memberships, one per project
      params[:project_ids].each do |project_id|
        @membership = Member.edit_membership(params[:membership_id], (params[:membership]|| {}).merge(:project_id => project_id), @group)
        @membership.save if request.post?
      end
    else # Single membership
      @membership = Member.edit_membership(params[:membership_id], params[:membership], @group)
      @membership.save if request.post?
    end
    
    respond_to do |format|
      if @membership.valid?
        format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'memberships' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-memberships", :partial => 'groups/memberships'
            page.visual_effect(:highlight, "member-#{@membership.id}")
          }
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_save_members, :errors => @membership.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end

  def destroy_membership
    @group = Group.find(params[:id])
    Member.find(params[:membership_id]).destroy if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'groups/memberships'} }
    end
  end
end
