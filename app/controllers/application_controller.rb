#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'uri'
require 'cgi'

class ApplicationController < ActionController::Base
  helper :all

  protected

  include Redmine::I18n

  layout 'base'
  exempt_from_layout 'builder', 'rsb'

  protect_from_forgery
  def handle_unverified_request
    super
    cookies.delete(:autologin)
  end

  # Remove broken cookie after upgrade from 0.8.x (#4292)
  # See https://rails.lighthouseapp.com/projects/8994/tickets/3360
  # TODO: remove it when Rails is fixed
  before_filter :delete_broken_cookies
  def delete_broken_cookies
    if cookies['_chiliproject_session'] && cookies['_chiliproject_session'] !~ /--/
      cookies.delete '_chiliproject_session'
      redirect_to home_path
      return false
    end
  end

  # FIXME: Remove this when all of Rack and Rails have learned how to
  # properly use encodings
  before_filter :params_filter
  def params_filter
    self.utf8nize!(params) if RUBY_VERSION >= '1.9'
  end
  def utf8nize!(obj)
    if obj.is_a? String
      obj.respond_to?(:force_encoding) ? obj.force_encoding("UTF-8") : obj
    elsif obj.is_a? Hash
      obj.each {|k, v| obj[k] = self.utf8nize!(v)}
    elsif obj.is_a? Array
      obj.each {|v| self.utf8nize!(v)}
    else
      obj
    end
  end

  before_filter :user_setup, :check_if_login_required, :set_localization
  filter_parameter_logging :password

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalid_authenticity_token

  include Redmine::Search::Controller
  include Redmine::MenuManager::MenuController
  helper Redmine::MenuManager::MenuHelper

  Redmine::Scm::Base.all.each do |scm|
    require_dependency "repository/#{scm.underscore}"
  end

  def user_setup
    # Check the settings cache for each request
    Setting.check_cache
    # Find the current user
    User.current = find_current_user
  end

  # Returns the current user or nil if no user is logged in
  # and starts a session if needed
  def find_current_user
    if session[:user_id]
      # existing session
      (User.active.find(session[:user_id]) rescue nil)
    elsif cookies[Redmine::Configuration['autologin_cookie_name']] && Setting.autologin?
      # auto-login feature starts a new session
      user = User.try_to_autologin(cookies[Redmine::Configuration['autologin_cookie_name']])
      session[:user_id] = user.id if user
      user
    elsif params[:format] == 'atom' && params[:key] && accept_key_auth_actions.include?(params[:action])
      # RSS key authentication does not start a session
      User.find_by_rss_key(params[:key])
    elsif Setting.rest_api_enabled? && api_request?
      if (key = api_key_from_request) && accept_key_auth_actions.include?(params[:action])
        # Use API key
        User.find_by_api_key(key)
      else
        # HTTP Basic, either username/password or API key/random
        authenticate_with_http_basic do |username, password|
          User.try_to_login(username, password) || User.find_by_api_key(username)
        end
      end
    end
  end

  # Sets the logged in user
  def logged_user=(user)
    reset_session
    if user && user.is_a?(User)
      User.current = user
      session[:user_id] = user.id
    else
      User.current = User.anonymous
    end
  end

  # check if login is globally required to access the application
  def check_if_login_required
    # no check needed if user is already logged in
    return true if User.current.logged?
    require_login if Setting.login_required?
  end

  def set_localization
    lang = nil
    if User.current.logged?
      lang = find_language(User.current.language)
    end
    if lang.nil? && request.env['HTTP_ACCEPT_LANGUAGE']
      accept_lang = parse_qvalues(request.env['HTTP_ACCEPT_LANGUAGE']).first
      if !accept_lang.blank?
        accept_lang = accept_lang.downcase
        lang = find_language(accept_lang) || find_language(accept_lang.split('-').first)
      end
    end
    lang ||= Setting.default_language
    set_language_if_valid(lang)
  end

  def require_login
    if !User.current.logged?
      # Extract only the basic url parameters on non-GET requests
      if request.get?
        url = url_for(params)
      else
        url = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id], :project_id => params[:project_id])
      end
      respond_to do |format|
        format.html { redirect_to :controller => "account", :action => "login", :back_url => url }
        format.atom { redirect_to :controller => "account", :action => "login", :back_url => url }
        format.xml  { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="ChiliProject API"' }
        format.js   { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="ChiliProject API"' }
        format.json { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="ChiliProject API"' }
      end
      return false
    end
    true
  end

  def require_admin
    return unless require_login
    if !User.current.admin?
      render_403
      return false
    end
    true
  end

  def deny_access
    User.current.logged? ? render_403 : require_login
  end

  # Authorize the user for the requested action
  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project || @projects, :global => global)
    if allowed
      true
    else
      if @project && @project.archived?
        render_403 :message => :notice_not_authorized_archived_project
      else
        deny_access
      end
    end
  end

  # Authorize the user for the requested action outside a project
  def authorize_global(ctrl = params[:controller], action = params[:action], global = true)
    authorize(ctrl, action, global)
  end

  # Find project of id params[:id]
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find project of id params[:project_id]
  def find_project_by_project_id
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find a project based on params[:project_id]
  # TODO: some subclasses override this, see about merging their logic
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds and sets @project based on @object.project
  def find_project_from_association
    render_404 unless @object.present?

    @project = @object.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_model_object
    model = self.class.read_inheritable_attribute('model_object')
    if model
      @object = model.find(params[:id])
      self.instance_variable_set('@' + controller_name.singularize, @object) if @object
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def self.model_object(model)
    write_inheritable_attribute('model_object', model)
  end

  # Filter for bulk issue operations
  def find_issues
    @issues = Issue.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @issues.empty?
    @projects = @issues.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Check if project is unique before bulk operations
  def check_project_uniqueness
    unless @project
      # TODO: let users bulk edit/move/destroy issues from different projects
      render_error 'Can not bulk edit/move/destroy issues from different projects'
      return false
    end
  end

  # make sure that the user is a member of the project (or admin) if project is private
  # used as a before_filter for actions that do not require any particular permission on the project
  def check_project_privacy
    if @project && @project.active?
      if @project.is_public? || User.current.member_of?(@project) || User.current.admin?
        true
      else
        User.current.logged? ? render_403 : require_login
      end
    else
      @project = nil
      render_404
      false
    end
  end

  def back_url
    params[:back_url] || request.env['HTTP_REFERER']
  end

  def redirect_back_or_default(default)
    back_url = URI.escape(CGI.unescape(params[:back_url].to_s))
    if !back_url.blank?
      begin
        uri = URI.parse(back_url)
        # do not redirect user to another host or to the login or register page
        if (uri.relative? || (uri.host == request.host)) && !uri.path.match(%r{/(login|account/register)})
          redirect_to(back_url)
          return
        end
      rescue URI::InvalidURIError
        # redirect to default
      end
    end
    redirect_to default
    false
  end

  def render_403(options={})
    @project = nil
    render_error({:message => :notice_not_authorized, :status => 403}.merge(options))
    return false
  end

  def render_404(options={})
    render_error({:message => :notice_file_not_found, :status => 404}.merge(options))
    return false
  end

  def render_500(options={})
    message = t(:notice_internal_server_error, :app_title => Setting.app_title)

    if $!.is_a?(ActionView::ActionViewError)
      @template.instance_variable_set("@project", nil)
      @template.instance_variable_set("@status", 500)
      @template.instance_variable_set("@message", message)
    else
      @project = nil
    end

    render_error({:message => message}.merge(options))
    return false
  end

  def render_optional_error_file(status_code)
    user_setup unless User.current.logged?

    case status_code
    when :not_found
      render_404
    when :internal_server_error
      render_500
    else
      super
    end
  end

  # Renders an error response
  def render_error(arg)
    arg = {:message => arg} unless arg.is_a?(Hash)

    @message = arg[:message]
    @message = l(@message) if @message.is_a?(Symbol)
    @status = arg[:status] || 500

    respond_to do |format|
      format.html {
        render :template => 'common/error', :layout => use_layout, :status => @status
      }
      format.atom { head @status }
      format.xml { head @status }
      format.js { head @status }
      format.json { head @status }
    end
  end

  # Picks which layout to use based on the request
  #
  # @return [boolean, string] name of the layout to use or false for no layout
  def use_layout
    request.xhr? ? false : 'base'
  end

  def invalid_authenticity_token
    if api_request?
      logger.error "Form authenticity token is missing or is invalid. API calls must include a proper Content-type header (text/xml or text/json)."
    end
    render_error "Invalid form authenticity token."
  end

  def render_feed(items, options={})
    @items = items || []
    @items.sort! {|x,y| y.event_datetime <=> x.event_datetime }
    @items = @items.slice(0, Setting.feeds_limit.to_i)
    @title = options[:title] || Setting.app_title
    render :template => "common/feed.atom.rxml", :layout => false, :content_type => 'application/atom+xml'
  end

  def self.accept_key_auth(*actions)
    actions = actions.flatten.map(&:to_s)
    write_inheritable_attribute('accept_key_auth_actions', actions)
  end

  def accept_key_auth_actions
    self.class.read_inheritable_attribute('accept_key_auth_actions') || []
  end

  # Returns the number of objects that should be displayed
  # on the paginated list
  def per_page_option
    per_page = nil
    if params[:per_page] && Setting.per_page_options_array.include?(params[:per_page].to_s.to_i)
      per_page = params[:per_page].to_s.to_i
      session[:per_page] = per_page
    elsif session[:per_page]
      per_page = session[:per_page]
    else
      per_page = Setting.per_page_options_array.first || 25
    end
    per_page
  end

  # Returns offset and limit used to retrieve objects
  # for an API response based on offset, limit and page parameters
  def api_offset_and_limit(options=params)
    if options[:offset].present?
      offset = options[:offset].to_i
      if offset < 0
        offset = 0
      end
    end
    limit = options[:limit].to_i
    if limit < 1
      limit = 25
    elsif limit > 100
      limit = 100
    end
    if offset.nil? && options[:page].present?
      offset = (options[:page].to_i - 1) * limit
      offset = 0 if offset < 0
    end
    offset ||= 0

    [offset, limit]
  end

  # qvalues http header parser
  # code taken from webrick
  def parse_qvalues(value)
    tmp = []
    if value
      parts = value.split(/,\s*/)
      parts.each {|part|
        if m = %r{^([^\s,]+?)(?:;\s*q=(\d+(?:\.\d+)?))?$}.match(part)
          val = m[1]
          q = (m[2] or 1).to_f
          tmp.push([val, q])
        end
      }
      tmp = tmp.sort_by{|val, q| -q}
      tmp.collect!{|val, q| val}
    end
    return tmp
  rescue
    nil
  end

  # Returns a string that can be used as filename value in Content-Disposition header
  def filename_for_content_disposition(name)
    request.env['HTTP_USER_AGENT'] =~ %r{MSIE} ? ERB::Util.url_encode(name) : name
  end

  def api_request?
    %w(xml json).include? params[:format]
  end

  # Returns the API key present in the request
  def api_key_from_request
    if params[:key].present?
      params[:key]
    elsif request.headers["X-ChiliProject-API-Key"].present?
      request.headers["X-ChiliProject-API-Key"]
    end
  end

  # Renders a warning flash if obj has unsaved attachments
  def render_attachment_warning_if_needed(obj)
    flash[:warning] = l(:warning_attachments_not_saved, obj.unsaved_attachments.size) if obj.unsaved_attachments.present?
  end

  # Sets the `flash` notice or error based the number of issues that did not save
  #
  # @param [Array, Issue] issues all of the saved and unsaved Issues
  # @param [Array, Integer] unsaved_issue_ids the issue ids that were not saved
  def set_flash_from_bulk_issue_save(issues, unsaved_issue_ids)
    if unsaved_issue_ids.empty?
      flash[:notice] = l(:notice_successful_update) unless issues.empty?
    else
      flash[:error] = l(:notice_failed_to_save_issues,
                        :count => unsaved_issue_ids.size,
                        :total => issues.size,
                        :ids => '#' + unsaved_issue_ids.join(', #'))
    end
  end

  # Rescues an invalid query statement. Just in case...
  def query_statement_invalid(exception)
    logger.error "Query::StatementInvalid: #{exception.message}" if logger
    session.delete(:query)
    sort_clear if respond_to?(:sort_clear)
    render_error "An error occurred while executing the query and has been logged. Please report this error to your administrator."
  end

  # Converts the errors on an ActiveRecord object into a common JSON format
  def object_errors_to_json(object)
    object.errors.collect do |attribute, error|
      { attribute => error }
    end.to_json
  end

  # Renders API response on validation failure
  def render_validation_errors(object)
    options = { :status => :unprocessable_entity, :layout => false }
    options.merge!(case params[:format]
      when 'xml';  { :xml =>  object.errors }
      when 'json'; { :json => {'errors' => object.errors} } # ActiveResource client compliance
      else
        raise "Unknown format #{params[:format]} in #render_validation_errors"
      end
    )
    render options
  end

  # Overrides #default_template so that the api template
  # is used automatically if it exists
  def default_template(action_name = self.action_name)
    if api_request?
      begin
        return self.view_paths.find_template(default_template_name(action_name), 'api')
      rescue ::ActionView::MissingTemplate
        # the api template was not found
        # fallback to the default behaviour
      end
    end
    super
  end

  # Overrides #pick_layout so that #render with no arguments
  # doesn't use the layout for api requests
  def pick_layout(*args)
    api_request? ? nil : super
  end
end
