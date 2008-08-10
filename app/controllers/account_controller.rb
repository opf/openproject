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
  helper :custom_fields
  include CustomFieldsHelper   
  
  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required, :only => [:login, :lost_password, :register, :activate]

  # Show user's account
  def show
    @user = User.find_active(params[:id])
    @custom_values = @user.custom_values.find(:all, :include => :custom_field)
    
    # show only public projects and private projects that the logged in user is also a member of
    @memberships = @user.memberships.select do |membership|
      membership.project.is_public? || (User.current.member_of?(membership.project))
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Login request and validation
  def login
    if request.get?
      # Logout user
      self.logged_user = nil
    else
      # Authenticate user
      user = User.try_to_login(params[:username], params[:password])
      if user.nil?
        # Invalid credentials
        flash.now[:error] = l(:notice_account_invalid_creditentials)
      elsif user.new_record?
        # Onthefly creation failed, display the registration form to fill/fix attributes
        @user = user
        session[:auth_source_registration] = {:login => user.login, :auth_source_id => user.auth_source_id }
        render :action => 'register'
      else
        # Valid user
        self.logged_user = user
        # generate a key and set cookie if autologin
        if params[:autologin] && Setting.autologin?
          token = Token.create(:user => user, :action => 'autologin')
          cookies[:autologin] = { :value => token.value, :expires => 1.year.from_now }
        end
        redirect_back_or_default :controller => 'my', :action => 'page'
      end
    end
  end

  # Log out current user and redirect to welcome page
  def logout
    cookies.delete :autologin
    Token.delete_all(["user_id = ? AND action = ?", User.current.id, 'autologin']) if User.current.logged?
    self.logged_user = nil
    redirect_to home_url
  end
  
  # Enable user to choose a new password
  def lost_password
    redirect_to(home_url) && return unless Setting.lost_password?
    if params[:token]
      @token = Token.find_by_action_and_value("recovery", params[:token])
      redirect_to(home_url) && return unless @token and !@token.expired?
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
        flash.now[:error] = l(:notice_account_unknown_email) and return unless user
        # user uses an external authentification
        flash.now[:error] = l(:notice_can_t_change_password) and return if user.auth_source_id
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
    redirect_to(home_url) && return unless Setting.self_registration? || session[:auth_source_registration]
    if request.get?
      session[:auth_source_registration] = nil
      @user = User.new(:language => Setting.default_language)
    else
      @user = User.new(params[:user])
      @user.admin = false
      @user.status = User::STATUS_REGISTERED
      if session[:auth_source_registration]
        @user.status = User::STATUS_ACTIVE
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
        if @user.save
          session[:auth_source_registration] = nil
          self.logged_user = @user
          flash[:notice] = l(:notice_account_activated)
          redirect_to :controller => 'my', :action => 'account'
        end
      else
        @user.login = params[:user][:login]
        @user.password, @user.password_confirmation = params[:password], params[:password_confirmation]
        case Setting.self_registration
        when '1'
          # Email activation
          token = Token.new(:user => @user, :action => "register")
          if @user.save and token.save
            Mailer.deliver_register(token)
            flash[:notice] = l(:notice_account_register_done)
            redirect_to :action => 'login'
          end
        when '3'
          # Automatic activation
          @user.status = User::STATUS_ACTIVE
          if @user.save
            self.logged_user = @user
            flash[:notice] = l(:notice_account_activated)
            redirect_to :controller => 'my', :action => 'account'
          end
        else
          # Manual activation by the administrator
          if @user.save
            # Sends an email to the administrators
            Mailer.deliver_account_activation_request(@user)
            flash[:notice] = l(:notice_account_pending)
            redirect_to :action => 'login'
          end
        end
      end
    end
  end
  
  # Token based account activation
  def activate
    redirect_to(home_url) && return unless Setting.self_registration? && params[:token]
    token = Token.find_by_action_and_value('register', params[:token])
    redirect_to(home_url) && return unless token and !token.expired?
    user = token.user
    redirect_to(home_url) && return unless user.status == User::STATUS_REGISTERED
    user.status = User::STATUS_ACTIVE
    if user.save
      token.destroy
      flash[:notice] = l(:notice_account_activated)
    end
    redirect_to :action => 'login'
  end
  
private
  def logged_user=(user)
    if user && user.is_a?(User)
      User.current = user
      session[:user_id] = user.id
    else
      User.current = User.anonymous
      session[:user_id] = nil
    end
  end
end
