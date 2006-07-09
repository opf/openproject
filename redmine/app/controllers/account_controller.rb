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

class AccountController < ApplicationController
  layout 'base'	
  
  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required, :only => :login
  before_filter :require_login, :except => [:show, :login]

  def show
    @user = User.find(params[:id])
  end

  # Login request and validation
  def login
    if request.get?
      session[:user] = nil
    else
      logged_in_user = User.try_to_login(params[:login], params[:password])
      if logged_in_user
        session[:user] = logged_in_user
        redirect_back_or_default :controller => 'account', :action => 'my_page'
      else
        flash[:notice] = _('Invalid user/password')
      end
    end
  end
	
	# Log out current user and redirect to welcome page
	def logout
		session[:user] = nil
		redirect_to(:controller => '')
	end

	def my_page
		@user = session[:user]		
		@reported_issues = Issue.find(:all, :conditions => ["author_id=?", @user.id], :limit => 10, :include => [ :status, :project, :tracker ], :order => 'issues.updated_on DESC')
		@assigned_issues = Issue.find(:all, :conditions => ["assigned_to_id=?", @user.id], :limit => 10, :include => [ :status, :project, :tracker ], :order => 'issues.updated_on DESC')
	end
  
	# Edit current user's account
	def my_account
		@user = User.find(session[:user].id)
		if request.post? and @user.update_attributes(@params[:user])
			flash[:notice] = 'Account was successfully updated.'
      session[:user] = @user
      set_localization
		end
	end
	
  # Change current user's password
  def change_password
    @user = User.find(session[:user].id)
    if @user.check_password?(@params[:password])
      @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
      flash[:notice] = 'Password was successfully updated.' if @user.save
    else
      flash[:notice] = 'Wrong password'
    end
    render :action => 'my_account'
  end
end
