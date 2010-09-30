# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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
  layout 'admin'
  
  before_filter :require_admin, :except => :show

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper   

  def index
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)
    
    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end
    
    @user_count = User.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count,
								per_page_option,
								params['page']								
    @users =  User.find :all,:order => sort_clause,
                        :conditions => c.conditions,
						:limit  =>  @user_pages.items_per_page,
						:offset =>  @user_pages.current.offset

    render :layout => !request.xhr?	
  end
  
  def show
    @user = User.find(params[:id])
    @custom_values = @user.custom_values
    
    # show projects based on current user visibility
    @memberships = @user.memberships.all(:conditions => Project.visible_by(User.current))
    
    events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
    @events_by_day = events.group_by(&:event_date)
    
    unless User.current.admin?
      if !@user.active? || (@user != User.current  && @memberships.empty? && events.empty?)
        render_404
        return
      end
    end
    render :layout => 'base'

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new
    @notification_options = User::MAIL_NOTIFICATION_OPTIONS
    @notification_option = Setting.default_notification_option

    @user = User.new(:language => Setting.default_language)
    @auth_sources = AuthSource.find(:all)
  end
  
  verify :method => :post, :only => :create, :render => {:nothing => true, :status => :method_not_allowed }
  def create
    @notification_options = User::MAIL_NOTIFICATION_OPTIONS
    @notification_option = Setting.default_notification_option

    @user = User.new(params[:user])
    @user.admin = params[:user][:admin] || false
    @user.login = params[:user][:login]
    @user.password, @user.password_confirmation = params[:password], params[:password_confirmation] unless @user.auth_source_id

    # TODO: Similar to My#account
    @user.mail_notification = params[:notification_option] || 'only_my_events'
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (params[:notification_option] == 'selected' ? params[:notified_project_ids] : [])

      Mailer.deliver_account_information(@user, params[:password]) if params[:send_information]
      flash[:notice] = l(:notice_successful_create)
      redirect_to(params[:continue] ? {:controller => 'users', :action => 'new'} : 
                                      {:controller => 'users', :action => 'edit', :id => @user})
      return
    else
      @auth_sources = AuthSource.find(:all)
      @notification_option = @user.mail_notification

      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    @notification_options = @user.valid_notification_options
    @notification_option = @user.mail_notification

    @auth_sources = AuthSource.find(:all)
    @membership ||= Member.new
  end
  
  verify :method => :put, :only => :update, :render => {:nothing => true, :status => :method_not_allowed }
  def update
    @user = User.find(params[:id])
    @notification_options = @user.valid_notification_options
    @notification_option = @user.mail_notification

    @user.admin = params[:user][:admin] if params[:user][:admin]
    @user.login = params[:user][:login] if params[:user][:login]
    if params[:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
      @user.password, @user.password_confirmation = params[:password], params[:password_confirmation]
    end
    @user.group_ids = params[:user][:group_ids] if params[:user][:group_ids]
    @user.attributes = params[:user]
    # Was the account actived ? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
    # TODO: Similar to My#account
    @user.mail_notification = params[:notification_option] || 'only_my_events'
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (params[:notification_option] == 'selected' ? params[:notified_project_ids] : [])

      if was_activated
        Mailer.deliver_account_activated(@user)
      elsif @user.active? && params[:send_information] && !params[:password].blank? && @user.auth_source_id.nil?
        Mailer.deliver_account_information(@user, params[:password])
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :back
    else
      @auth_sources = AuthSource.find(:all)
      @membership ||= Member.new

      render :action => :edit
    end
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'users', :action => 'edit', :id => @user
  end

  def edit_membership
    @user = User.find(params[:id])
    @membership = Member.edit_membership(params[:membership_id], params[:membership], @user)
    @membership.save if request.post?
    respond_to do |format|
      if @membership.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-memberships", :partial => 'users/memberships'
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
    @user = User.find(params[:id])
    @membership = Member.find(params[:membership_id])
    if request.post? && @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'users/memberships'} }
    end
  end
end
