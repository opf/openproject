# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

  def index
    list
    render :action => 'list'
  end

  def list
    sort_init 'login', 'asc'
    sort_update
    @user_count = User.count		
    @user_pages = Paginator.new self, @user_count,
								15,
								@params['page']								
    @users =  User.find :all,:order => sort_clause,
						:limit  =>  @user_pages.items_per_page,
						:offset =>  @user_pages.current.offset		
  end

  def add
    if request.get?
      @user = User.new
    else
      @user = User.new(params[:user])
      @user.admin = params[:user][:admin] || false
      @user.login = params[:user][:login]
      @user.password, @user.password_confirmation = params[:password], params[:password_confirmation]
      if @user.save
        flash[:notice] = 'User was successfully created.'
        redirect_to :action => 'list'
      end
    end
  end

  def edit
    @user = User.find(params[:id])
    if request.post?
      @user.admin = params[:user][:admin] if params[:user][:admin]
      @user.login = params[:user][:login] if params[:user][:login]
      @user.password, @user.password_confirmation = params[:password], params[:password_confirmation] unless params[:password].nil? or params[:password].empty?
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  rescue
    flash[:notice] = "Unable to delete user"
    redirect_to :action => 'list'
  end  
end
