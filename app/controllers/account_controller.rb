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

class AccountController < ApplicationController
  layout 'base'	
  helper :custom_fields
  include CustomFieldsHelper   
  
  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required, :only => [:login, :lost_password, :register]
  before_filter :require_login, :except => [:show, :login, :lost_password, :register]

  # Show user's account
  def show
    @user = User.find(params[:id])
    @custom_values = @user.custom_values.find(:all, :include => :custom_field)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Login request and validation
  def login
    if request.get?
      # Logout user
      self.logged_in_user = nil
    else
      # Authenticate user
      user = User.try_to_login(params[:login], params[:password])
      if user
        self.logged_in_user = user
        redirect_back_or_default :controller => 'my', :action => 'page'
      else
        flash.now[:notice] = l(:notice_account_invalid_creditentials)
      end
    end
  end

  # Log out current user and redirect to welcome page
  def logout
    self.logged_in_user = nil
    redirect_to :controller => 'welcome'
  end
  
  # Enable user to choose a new password
  def lost_password
    if params[:token]
      @token = Token.find_by_action_and_value("recovery", params[:token])
      redirect_to :controller => 'welcome' and return unless @token and !@token.expired?
      @user = @token.user
      if request.post?
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        if @user.save
          @token.destroy
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to :action => 'login'
          return
        end 
      end
      render :template => "account/password_recovery"
      return
    else
      if request.post?
        user = User.find_by_mail(params[:mail])
        # user not found in db
        flash.now[:notice] = l(:notice_account_unknown_email) and return unless user
        # user uses an external authentification
        flash.now[:notice] = l(:notice_can_t_change_password) and return if user.auth_source_id
        # create a new token for password recovery
        token = Token.new(:user => user, :action => "recovery")
        if token.save
          Mailer.deliver_lost_password(token)
          flash[:notice] = l(:notice_account_lost_email_sent)
          redirect_to :action => 'login'
          return
        end
      end
    end
  end
  
  # User self-registration
  def register
    redirect_to :controller => 'welcome' and return unless Setting.self_registration?
    if params[:token]
      token = Token.find_by_action_and_value("register", params[:token])
      redirect_to :controller => 'welcome' and return unless token and !token.expired?
      user = token.user
      redirect_to :controller => 'welcome' and return unless user.status == User::STATUS_REGISTERED
      user.status = User::STATUS_ACTIVE
      if user.save
        token.destroy
        flash[:notice] = l(:notice_account_activated)
        redirect_to :action => 'login'
        return
      end      
    else
      if request.get?
        @user = User.new(:language => Setting.default_language)
        @custom_values = UserCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @user) }
      else
        @user = User.new(params[:user])
        @user.admin = false
        @user.login = params[:user][:login]
        @user.status = User::STATUS_REGISTERED
        @user.password, @user.password_confirmation = params[:password], params[:password_confirmation]
        @custom_values = UserCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @user, :value => params["custom_fields"][x.id.to_s]) }
        @user.custom_values = @custom_values
        token = Token.new(:user => @user, :action => "register")
        if @user.save and token.save
          Mailer.deliver_register(token)
          flash[:notice] = l(:notice_account_register_done)
          redirect_to :controller => 'welcome' and return
        end
      end
    end
  end
end
