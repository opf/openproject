# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class UsersController < ApplicationController
  layout 'base'	
  before_filter :require_admin

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper   

  def index
    list
    render :action => 'list' unless request.xhr?
  end

  def list
    sort_init 'login', 'asc'
    sort_update
    
    @status = params[:status] ? params[:status].to_i : 1    
    conditions = nil
    conditions = ["status=?", @status] unless @status == 0
    
    @user_count = User.count(:conditions => conditions)
    @user_pages = Paginator.new self, @user_count,
								15,
								params['page']								
    @users =  User.find :all,:order => sort_clause,
                        :conditions => conditions,
						:limit  =>  @user_pages.items_per_page,
						:offset =>  @user_pages.current.offset

    render :action => "list", :layout => false if request.xhr?	
  end

  def add
    if request.get?
      @user = User.new(:language => Setting.default_language)
      @custom_values = UserCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @user) }
    else
      @user = User.new(params[:user])
      @user.admin = params[:user][:admin] || false
      @user.login = params[:user][:login]
      @user.password, @user.password_confirmation = params[:password], params[:password_confirmation] unless @user.auth_source_id
      @custom_values = UserCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @user, :value => params["custom_fields"][x.id.to_s]) }
      @user.custom_values = @custom_values			
      if @user.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'list'
      end
    end
    @auth_sources = AuthSource.find(:all)
  end

  def edit
    @user = User.find(params[:id])
    if request.get?
      @custom_values = UserCustomField.find(:all).collect { |x| @user.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x) }
    else
      @user.admin = params[:user][:admin] if params[:user][:admin]
      @user.login = params[:user][:login] if params[:user][:login]
      @user.password, @user.password_confirmation = params[:password], params[:password_confirmation] unless params[:password].nil? or params[:password].empty? or @user.auth_source_id
      if params[:custom_fields]
        @custom_values = UserCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @user, :value => params["custom_fields"][x.id.to_s]) }
        @user.custom_values = @custom_values
      end
      if @user.update_attributes(params[:user])
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'list'
      end
    end
    @auth_sources = AuthSource.find(:all)
    @roles = Role.find(:all, :order => 'position')
    @projects = Project.find(:all) - @user.projects
    @membership ||= Member.new
  end
  
  def edit_membership
    @user = User.find(params[:id])
    @membership = params[:membership_id] ? Member.find(params[:membership_id]) : Member.new(:user => @user)
    @membership.attributes = params[:membership]
    if request.post? and @membership.save
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :action => 'edit', :id => @user and return
  end
  
  def destroy_membership
    @user = User.find(params[:id])
    if request.post? and Member.find(params[:membership_id]).destroy
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :action => 'edit', :id => @user and return
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  rescue
    flash[:notice] = "Unable to delete user"
    redirect_to :action => 'list'
  end  
end
