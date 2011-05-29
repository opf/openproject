class UsersController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin, :except => :show
  before_filter :find_user, :only => [:show, :edit, :update, :edit_membership, :destroy_membership]
  accept_key_auth :index, :show, :create, :update

  include SortHelper
  include CustomFieldsHelper   

  def index
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)
    
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end
    
    scope = User
    scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?
    
    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end
    
    @user_count = scope.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @users =  scope.find :all,
                        :order => sort_clause,
                        :conditions => c.conditions,
                        :limit  =>  @limit,
                        :offset =>  @offset

    respond_to do |format|
      format.html {
        @groups = Group.all.sort
        render :layout => !request.xhr?
      }
      format.api
    end	
  end
  
  def show
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
    
    respond_to do |format|
      format.html { render :layout => 'base' }
      format.api
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
    @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] if @user.change_password_allowed?

    # TODO: Similar to My#account
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      Mailer.deliver_account_information(@user, params[:user][:password]) if params[:send_information]
      
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? 
            {:controller => 'users', :action => 'new'} : 
            {:controller => 'users', :action => 'edit', :id => @user}
          )
        }
        format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
      end
    else
      @auth_sources = AuthSource.find(:all)
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@user) }
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
    @user.safe_attributes = params[:user]
    if params[:user][:password].present? && @user.change_password_allowed?
      @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
    end
    # Was the account actived ? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
    # TODO: Similar to My#account
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      if was_activated
        Mailer.deliver_account_activated(@user)
      elsif @user.active? && params[:send_information] && !params[:user][:password].blank? && @user.change_password_allowed?
        Mailer.deliver_account_information(@user, params[:user][:password])
      end
      
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to :back
        }
        format.api  { head :ok }
      end
    else
      @auth_sources = AuthSource.find(:all)
      @membership ||= Member.new
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => :edit }
        format.api  { render_validation_errors(@user) }
      end
    end
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'users', :action => 'edit', :id => @user
  end

  def edit_membership
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
    @membership = Member.find(params[:membership_id])
    if request.post? && @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'users/memberships'} }
    end
  end
  
  private
  
  def find_user
    if params[:id] == 'current'
      require_login || return
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
