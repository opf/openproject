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

require 'uri'
require 'cgi'

# There is a circular dependency chain between User, Principal, and Project
# If anybody triggers the loading of User first, Rails fails to autoload
# the three. Defining class User depends on the resolution of the Principal constant.
# Triggering autoload of the User class does not immediately define the User constant
# while Principal and Project dont inherit from something undefined.
# This means they will be defined as constants right after their autoloading
# was triggered. When Rails discovers it has to load the undefined class User
# during the load circle while noticing it has already tried to load it (the
# first load of user), it will complain about user being an undefined constant.
# Requiring this dependency here ensures Principal is loaded first in development
# on each request.
require_dependency 'principal'


class ApplicationController < ActionController::Base
  # ensure the OpenProject models are required in the right order (as they have circular dependencies)

  class_attribute :_model_object
  class_attribute :_model_scope
  class_attribute :accept_key_auth_actions

  protected

  include Redmine::I18n

  layout 'base'

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

  before_filter :user_setup, :check_if_login_required, :reset_i18n_fallbacks, :set_localization, :check_session_lifetime

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalid_authenticity_token

  include Redmine::Search::Controller
  include Redmine::MenuManager::MenuController
  helper Redmine::MenuManager::MenuHelper

  # TODO: needed? redmine doesn't
  Redmine::Scm::Base.all.each do |scm|
    require "repository/#{scm.underscore}"
  end

  # the current user is a per-session kind of thing and session stuff is controller responsibility.
  # a globally accessible User.current is a big code smell. when used incorrectly it allows getting
  # the current user outside of a session scope, i.e. in the model layer, from mailers or in the console
  # which doesn't make any sense. for model code that needs to be aware of the current user, i.e. when
  # returning all visible projects for <somebody>, the controller should pass the current user to the model,
  # instead of letting it fetch it by itself through User.current.
  # this method acts as a reminder and wants to encourage you to use it.
  # - Project.visible_by actually allows the controller to pass in a user but it falls back to User.current
  #   and there are other places in the session-unaware codebase, that rely on User.current.)
  def current_user
    User.current
  end
  helper_method :current_user

  def user_setup
    # Find the current user
    User.current = find_current_user
  end

  # Returns the current user or nil if no user is logged in
  # and starts a session if needed
  def find_current_user
    if session[:user_id]
      # existing session
      (User.active.find(session[:user_id], :include => [:memberships]) rescue nil)
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
      session[:updated_at] = Time.now
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

  def reset_i18n_fallbacks
    return if I18n.fallbacks.defaults == (fallbacks = [I18n.default_locale] + Setting.available_languages.map(&:to_sym))
    I18n.fallbacks = nil
    I18n.fallbacks.defaults = fallbacks
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
        controller = "/#{params[:controller].to_s}" unless params[:controller].to_s.starts_with?('/')
        url = url_for(:controller => controller, :action => params[:action], :id => params[:id], :project_id => params[:project_id])
      end
      respond_to do |format|
        format.any(:html, :atom) { redirect_to signin_path(:back_url => url) }

        authentication_scheme = if request.headers["X-Authentication-Scheme"] == "Session"
          'Session'
        else
          'Basic'
        end
        format.any(:xml, :js, :json)  {
          head :unauthorized,
          "Reason" => "login needed",
          'WWW-Authenticate' => authentication_scheme + ' realm="OpenProject API"'
        }
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
    find_optional_project_and_raise_error
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project_and_raise_error(controller_name = nil)
    controller_name = params[:controller] if controller_name.nil?

    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => controller_name, :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  end

  # Finds and sets @project based on @object.project
  def find_project_from_association
    render_404 unless @object.present?

    @project = @object.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_model_object
    model = self.class._model_object
    if model
      @object = model.find(params[:id])
      self.instance_variable_set('@' + controller_name.singularize, @object) if @object
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_model_object_and_project
    if params[:id]
      model_object = self.class._model_object
      instance = model_object.find(params[:id])
      @project = instance.project
      self.instance_variable_set('@' + model_object.to_s.underscore, instance)
    else
      @project = Project.find(params[:project_id])
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # TODO: this method is right now only suited for controllers of objects that somehow have an association to Project
  def find_object_and_scope
    model_object = self.class._model_object.find(params[:id]) if params[:id].present?

    associations = self.class._model_scope + [Project]

    associated = find_belongs_to_chained_objects(associations, model_object)

    associated.each do |a|
      self.instance_variable_set('@' + a.class.to_s.downcase, a)
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # this method finds all records that are specified in the associations param
  # after the first object is found it traverses the belongs_to chain of that first object
  # if a start_object is provided it is taken as the starting point of the traversal
  # e.g associations [Message, Board, Project] finds Message by find(:message_id) then message.board
  # and board.project
  def find_belongs_to_chained_objects(associations, start_object = nil)
    associations.inject([start_object].compact) do |instances, association|
      scope_name, scope_association = association.is_a?(Hash) ?
                                        [association.keys.first.to_s.downcase, association.values.first] :
                                        [association.to_s.downcase, association.to_s.downcase]

      #TODO: Remove this hidden dependency on params
      instances << (instances.last.nil? ?
                      scope_name.camelize.constantize.find(params[:"#{scope_name}_id"]) :
                      instances.last.send(scope_association.to_sym))
      instances
    end
  end

  def self.model_object(model, options = {})
    self._model_object = model
    self._model_scope  = Array(options[:scope]) if options[:scope]
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
    user_setup unless User.current.id == session[:user_id]

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
      format.any(:atom, :xml, :js, :json, :pdf) { head @status }
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
    render :template => "common/feed", :layout => false, :content_type => 'application/atom+xml'
  end

  def self.accept_key_auth(*actions)
    actions = actions.flatten.map(&:to_s)
    self.accept_key_auth_actions = actions
  end

  def accept_key_auth_actions
    self.class.accept_key_auth_actions || []
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
    if params[:format].nil?
      %w(application/xml application/json).include? request.format.to_s
    else
      %w(xml json).include? params[:format]
    end
  end

  # Returns the API key present in the request
  def api_key_from_request
    if params[:key].present?
      params[:key]
    elsif request.headers["X-OpenProject-API-Key"].present?
      request.headers["X-OpenProject-API-Key"]
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
      flash[:error] = l(:notice_failed_to_save_work_packages,
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

  def default_breadcrumb
    name = l("label_" + self.class.name.gsub("Controller", "").underscore.singularize + "_plural")
    if name =~ /translation missing/i
      name = l("label_" + self.class.name.gsub("Controller", "").underscore.singularize)
    end
    name
  end
  helper_method :default_breadcrumb

  def disable_everything_except_api
    if !api_request?
      head 410
      return false
    end
    true
  end

  def disable_api
    if api_request?
      head 410
      return false
    end
    true
  end
  ActiveSupport.run_load_hooks(:application_controller, self)

  def check_session_lifetime
    if session_expired?
      self.logged_user = nil
      if request.get?
        url = url_for(params)
      else
        url = url_for(:controller => params[:controller], :action => params[:action],
                      :id => params[:id], :project_id => params[:project_id])
      end
      flash[:warning] = I18n.t('notice_forced_logout', :ttl_time => Setting.session_ttl)
      redirect_to(:controller => "account", :action => "login", :back_url => url)
    end
    session[:updated_at] = Time.now
  end

  private

  def session_expired?
    current_user.logged? &&
    (session_ttl_enabled? && (session[:updated_at].nil? ||
                             (session[:updated_at] + Setting.session_ttl.to_i.minutes) < Time.now))
  end

  def session_ttl_enabled?
    Setting.session_ttl_enabled? && Setting.session_ttl.to_i >= 5
  end

  def permitted_params
    @permitted_params ||= PermittedParams.new(params, current_user)
  end
end
