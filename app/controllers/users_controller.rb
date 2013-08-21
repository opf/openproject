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

class UsersController < ApplicationController
  layout 'admin'

  before_filter :disable_api
  before_filter :require_admin, :except => [:show, :deletion_info, :destroy]
  before_filter :find_user, :only => [:show,
                                      :edit,
                                      :update,
                                      :change_status,
                                      :edit_membership,
                                      :destroy_membership,
                                      :destroy,
                                      :deletion_info]
  before_filter :require_login, :only => [:deletion_info] # should also contain destroy but post data can not be redirected
  before_filter :authorize_for_user, :only => [:destroy]
  before_filter :check_if_deletion_allowed, :only => [:deletion_info,
                                                      :destroy]
  accept_key_auth :index, :show, :create, :update, :destroy

  include SortHelper
  include CustomFieldsHelper
  include PaginationHelper

  def index
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)

    scope = User
    scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?
    c = ARCondition.new

    if params[:status] == 'blocked'
      @status = :blocked
      scope = scope.blocked
    elsif params[:status] == 'all'
      @status = :all
      scope = scope.not_builtin
    else
      @status = params[:status] ? params[:status].to_i : User::STATUSES[:active]
      scope = scope.not_blocked if @status == User::STATUSES[:active]
      c << ["status = ?", @status]
    end

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end

    @users = scope.order(sort_clause)
                  .where(c.conditions)
                  .page(page_param)
                  .per_page(per_page_param)

    respond_to do |format|
      format.html {
        @groups = Group.all.sort
        render :layout => !request.xhr?
      }
    end
  end

  def show
    # show projects based on current user visibility
    @memberships = @user.memberships.all(:conditions => Project.visible_by(User.current))

    events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
    @events_by_day = events.map(&:data).group_by(&:event_date)

    unless User.current.admin?
      if !(@user.active? || @user.registered?) || (@user != User.current  && @memberships.empty? && events.empty?)
        render_404
        return
      end
    end

    respond_to do |format|
      format.html { render :layout => 'base' }
    end
  end

  def new
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @auth_sources = AuthSource.find(:all)
  end

  verify :method => :post, :only => :create, :render => {:nothing => true, :status => :method_not_allowed }
  def create
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @user.safe_attributes = params[:user]
    @user.admin = params[:user][:admin] || false
    @user.login = params[:user][:login]
    if @user.change_password_allowed?
      if params[:user][:assign_random_password]
        @user.random_password!
      else 
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
      end
    end

    if @user.save
      # TODO: Similar to My#account
      @user.pref.attributes = params[:pref]
      @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
      @user.pref.save

      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      UserMailer.account_information(@user, @user.password).deliver if params[:send_information]

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ?
            new_user_path :
            edit_user_path(@user)
          )
        }
      end
    else
      @auth_sources = AuthSource.find(:all)
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @auth_sources = AuthSource.find(:all)
    @membership ||= Member.new
  end

  verify :method => :put, :only => :update, :render => {:nothing => true, :status => :method_not_allowed }
  def update
    @user.admin = params[:user][:admin] if params[:user][:admin]
    @user.login = params[:user][:login] if params[:user][:login]
    @user.attributes = permitted_params.user_update_as_admin
    if @user.change_password_allowed?
      if params[:user][:assign_random_password]
        @user.random_password!
      elsif params[:user][:password].present?
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
      end
    end

    if @user.save
      # TODO: Similar to My#account
      @user.pref.attributes = params[:pref]
      @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
      @user.pref.save

      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      if @user.active? && params[:send_information] && !@user.password.blank? && @user.change_password_allowed?
        UserMailer.account_information(@user, @user.password).deliver
      end

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to :back
        }
      end
    else
      @auth_sources = AuthSource.find(:all)
      @membership ||= Member.new
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => :edit }
      end
    end
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => '/users', :action => 'edit', :id => @user
  end

  def change_status
    if @user.id == current_user.id
      # user is not allowed to change own status
      redirect_back_or_default(:action => 'edit', :id => @user)
      return
    end
    if params[:unlock]
      @user.failed_login_count = 0
      @user.activate
    elsif params[:lock]
      @user.lock
    elsif params[:activate]
      @user.activate
    end
    # Was the account activated? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUSES[:registered],
                                             User::STATUSES[:active]])
    if @user.save
      flash[:notice] = I18n.t(:notice_successful_update)
      if was_activated
        UserMailer.account_activated(@user).deliver
      end
    else
      flash[:error] = I18n.t(:error_status_change_failed,
                             :errors => @user.errors.full_messages.join(', '),
                             :scope => :user)
    end
    redirect_back_or_default(:action => 'edit', :id => @user)
  end

  def edit_membership
    @membership = Member.edit_membership(params[:membership_id], params[:membership], @user)
    @membership.save if request.post?
    respond_to do |format|
      if @membership.valid?
        format.html { redirect_to :controller => '/users', :action => 'edit', :id => @user, :tab => 'memberships' }
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

  def destroy
    # as destroying users is a lengthy process we handle it in the background
    # and lock the account now so that no action can be performed with it
    @user.status = User::STATUSES[:locked]
    @user.save

    # TODO: use Delayed::Worker.delay_jobs = false in test environment as soon as
    # delayed job allows for it
    Rails.env.test? ?
      @user.destroy :
      @user.delay.destroy

    flash[:notice] = l('account.deleted')

    respond_to do |format|
      format.html do
        if @user == User.current
          logged_user = nil
          redirect_to signin_path
        else
          redirect_to users_path
        end
      end
    end
  end

  def destroy_membership
    @membership = Member.find(params[:membership_id])
    if request.post? && @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => '/users', :action => 'edit', :id => @user, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'users/memberships'} }
    end
  end

  def deletion_info
    render :action => 'deletion_info', :layout => my_or_admin_layout
  end

  private

  def find_user
    if params[:id] == 'current' || params['id'].nil?
      require_login || return
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_for_user
    if (User.current != @user ||
        User.current == User.anonymous) &&
       !User.current.admin?

      respond_to do |format|
        format.html { render_403 }
        format.xml  { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="OpenProject API"' }
        format.js   { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="OpenProject API"' }
        format.json { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="OpenProject API"' }
      end

      false
    end
  end

  def check_if_deletion_allowed
    if (User.current.admin && @user != User.current && !Setting.users_deletable_by_admins?) ||
       (User.current == @user && !Setting.users_deletable_by_self?)
      render_404
      false
    end
  end

  def my_or_admin_layout
    # TODO: how can this be done better:
    # check if the route used to call the action is in the 'my' namespace
    if url_for(:delete_my_account_info) == request.url
      'my'
    else
      'admin'
    end
  end
end
