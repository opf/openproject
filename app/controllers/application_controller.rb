#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'uri'
require 'cgi'

class ApplicationController < ActionController::Base
  class_attribute :_model_object
  class_attribute :_model_scope
  class_attribute :accept_key_auth_actions

  helper_method :render_to_string

  protected

  include I18n
  include Redmine::I18n
  include HookHelper
  include ::OpenProject::Authentication::SessionExpiry

  layout 'base'

  protect_from_forgery
  # CSRF protection prevents two things. It prevents an attacker from using a
  # user's session to execute requests. It also prevents an attacker to log in
  # a user with the attacker's account. API requests each contain their own
  # authentication token, e.g. as key parameter or header, so they don't have
  # to be protected by CSRF protection as long as they don't create a session
  #
  # We can't reliably determine here whether a request is an API
  # request as this happens in our way too complex find_current_user method
  # that is only executed after this method. E.g we might have to check that
  # no session is active and that no autologin cookie is set.
  #
  # Thus, we always reset any active session and the autologin cookie to make
  # sure find_current user doesn't find a user based on an active session.
  #
  # Nevertheless, API requests should not be aborted, which they would be
  # if we raised an error here. Still, users should see an error message
  # when sending a form with a wrong CSRF token (e.g. after session expiration).
  # Thus, we show an error message unless the request probably is an API
  # request.
  def handle_unverified_request
    super
    cookies.delete(OpenProject::Configuration['autologin_cookie_name'])
    self.logged_user = nil

    # Don't render an error message for requests that appear to be API requests.
    #
    # The api_request? method uses the format parameter or a header
    # to determine whether a request is an API request. Unfortunately, having
    # an API request doesn't mean we don't use a session for authentication.
    # Also, attackers can send CSRF requests with arbitrary headers using
    # browser plugins. For more information on this, see:
    # http://weblog.rubyonrails.org/2011/2/8/csrf-protection-bypass-in-ruby-on-rails/
    #
    # Resetting the session above is enough for preventing an attacking from
    # using a user's session to execute requests with the user's account.
    #
    # It's not enough to prevent login CSRF, so we have to explicitly deny requests
    # with invalid CSRF token for all requests that create a session with a logged in
    # user. This is implemented as a before filter on AccountController that disallows
    # all requests classified as API calls by api_request (via disable_api). It's
    # important that disable_api and handle_unverified_request both use the same method
    # to determine whether a request is an API request to ensure that a request either
    # has a valid CSRF token and is not classified as API request, so no error is raised
    # here OR a request has an invalid CSRF token and is classified as API request, no error
    # is raised here, but is denied by disable_api.
    #
    # See http://stackoverflow.com/a/15350123 for more information on login CSRF.
    unless api_request?

      # Check whether user have cookies enabled, otherwise they'll only be
      # greeted with the CSRF error upon login.
      message = I18n.t(:error_token_authenticity)
      message << ' ' + I18n.t(:error_cookie_missing) if openproject_cookie_missing?
      render_error status: 422, message: message
    end
  end

  rescue_from ActionController::ParameterMissing do |exception|
    render body:   "Required parameter missing: #{exception.param}",
           status: :bad_request
  end

  before_action :user_setup,
                :check_if_login_required,
                :log_requesting_user,
                :reset_i18n_fallbacks,
                :set_localization,
                :check_session_lifetime,
                :stop_if_feeds_disabled,
                :set_cache_buster,
                :reload_mailer_configuration!

  include Redmine::Search::Controller
  include Redmine::MenuManager::MenuController
  helper Redmine::MenuManager::MenuHelper

  def default_url_options(_options = {})
    {
      layout: params['layout'],
      protocol: Setting.protocol
    }
  end

  # set http headers so that the browser does not store any
  # data (caches) of this site
  # see:
  # https://websecuritytool.codeplex.com/wikipage?title=Checks#http-cache-control-header-no-store
  # http://stackoverflow.com/questions/711418/how-to-prevent-browser-page-caching-in-rails
  def set_cache_buster
    if OpenProject::Configuration['disable_browser_cache']
      response.cache_control.merge!(
        max_age: 0,
        public: false,
        must_revalidate: true
      )
    end
  end

  def reload_mailer_configuration!
    OpenProject::Configuration.reload_mailer_configuration!
  end

  # The current user is a per-session kind of thing and session stuff is controller responsibility.
  # A globally accessible User.current is a big code smell. When used incorrectly it allows getting
  # the current user outside of a session scope, i.e. in the model layer, from mailers or
  # in the console which doesn't make any sense. For model code that needs to be aware of the
  # current user, i.e. when returning all visible projects for <somebody>, the controller should
  # pass the current user to the model, instead of letting it fetch it by itself through
  # `User.current`. This method acts as a reminder and wants to encourage you to use it.
  # Project.visible_by actually allows the controller to pass in a user but it falls back
  # to `User.current` and there are other places in the session-unaware codebase,
  # that rely on `User.current`.
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
      User.active.find_by(id: session[:user_id])
    elsif cookies[OpenProject::Configuration['autologin_cookie_name']] && Setting.autologin?
      # auto-login feature starts a new session
      user = User.try_to_autologin(cookies[OpenProject::Configuration['autologin_cookie_name']])
      session[:user_id] = user.id if user
      user
    elsif params[:format] == 'atom' && params[:key] && accept_key_auth_actions.include?(params[:action])
      # RSS key authentication does not start a session
      User.find_by_rss_key(params[:key])
    elsif Setting.rest_api_enabled? && api_request?
      if (key = api_key_from_request) && accept_key_auth_actions.include?(params[:action])
        # Use API key
        User.find_by_api_key(key)
      elsif OpenProject::Configuration.apiv2_enable_basic_auth?
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
      InitializeSessionService.call(user, session)
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

  # Checks if the session cookie is missing.
  # This is useful only on a second request
  def openproject_cookie_missing?
    request.cookies[OpenProject::Configuration['session_cookie_name']].nil?
  end
  helper_method :openproject_cookie_missing?

  def log_requesting_user
    return unless Setting.log_requesting_user?
    login_and_mail = " (#{escape_for_logging(User.current.login)} ID: #{User.current.id} " \
                     "<#{escape_for_logging(User.current.mail)}>)" unless User.current.anonymous?
    logger.info "OpenProject User: #{escape_for_logging(User.current.name)}#{login_and_mail}"
  end

  # Escape string to prevent log injection
  # e.g. setting the user name to contain \r allows overwriting a log line on console
  # replaces all invalid characters with #
  def escape_for_logging(string)
    # only allow numbers, ASCII letters, space and the following characters: @.-"'!?=/
    string.gsub(/[^0-9a-zA-Z@._\-"\'!\?=\/ ]{1}/, '#')
  end

  def reset_i18n_fallbacks
    return if I18n.fallbacks.defaults == (fallbacks = [I18n.default_locale] + Setting.available_languages.map(&:to_sym))
    I18n.fallbacks = nil
    I18n.fallbacks.defaults = fallbacks
  end

  def set_localization
    SetLocalizationService.new(User.current, request.env['HTTP_ACCEPT_LANGUAGE']).call
  end

  def require_login
    unless User.current.logged?
      respond_to do |format|
        format.any(:html, :atom) do redirect_to signin_path(back_url: login_back_url) end

        auth_header = OpenProject::Authentication::WWWAuthenticate.response_header(
          request_headers: request.headers)

        format.any(:xml, :js, :json)  do
          head :unauthorized,
               'X-Reason' => 'login needed',
               'WWW-Authenticate' => auth_header
        end
      end
      return false
    end
    true
  end

  def require_admin
    return unless require_login
    unless User.current.admin?
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
    context = @project || @projects
    is_authorized = AuthorizationService.new({ controller: ctrl, action: action }, context: context, global: global).call

    unless is_authorized
      if @project && @project.archived?
        render_403 message: :notice_not_authorized_archived_project
      else
        deny_access
      end
    end
    is_authorized
  end

  # Authorize the user for the requested action outside a project
  def authorize_global(ctrl = params[:controller], action = params[:action], global = true)
    authorize(ctrl, action, global)
  end

  # Find project of id params[:id]
  # Note: find() is Project.friendly.find()
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Find project of id params[:project_id]
  # Note: find() is Project.friendly.find()
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
    allowed = User.current.allowed_to?({ controller: controller_name, action: params[:action] },
                                       @project, global: true)
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
      instance_variable_set('@' + controller_name.singularize, @object) if @object
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_model_object_and_project
    if params[:id]
      model_object = self.class._model_object
      instance = model_object.find(params[:id])
      @project = instance.project
      instance_variable_set('@' + model_object.to_s.underscore, instance)
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
      instance_variable_set('@' + a.class.to_s.downcase, a)
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # this method finds all records that are specified in the associations param
  # after the first object is found it traverses the belongs_to chain of that first object
  # if a start_object is provided it is taken as the starting point of the traversal
  # e.g associations [Message, Board, Project] finds Message by find(:message_id)
  # then message.board and board.project
  def find_belongs_to_chained_objects(associations, start_object = nil)
    associations.inject([start_object].compact) do |instances, association|
      scope_name, scope_association = association.is_a?(Hash) ?
                                        [association.keys.first.to_s.downcase, association.values.first] :
                                        [association.to_s.downcase, association.to_s.downcase]

      # TODO: Remove this hidden dependency on params
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

  # Filter for bulk work package operations
  def find_work_packages
    @work_packages = WorkPackage.includes(:project)
                     .where(id: params[:work_package_id] || params[:ids])
                     .order('id ASC')
    fail ActiveRecord::RecordNotFound if @work_packages.empty?
    @projects = @work_packages.map(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Make sure that the user is a member of the project (or admin) if project is private
  # used as a before_action for actions that do not require any particular permission
  # on the project.
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

  def redirect_back_or_default(default, use_escaped = true)
    policy = RedirectPolicy.new(
      params[:back_url],
      hostname: request.host,
      default: default,
      return_escaped: use_escaped,
    )

    redirect_to policy.redirect_url
  end

  def render_400(options = {})
    @project = nil
    render_error({ message: :notice_bad_request, status: 400 }.merge(options))
    false
  end

  def render_403(options = {})
    @project = nil
    render_error({ message: :notice_not_authorized, status: 403 }.merge(options))
    false
  end

  def render_404(options = {})
    render_error({ message: :notice_file_not_found, status: 404 }.merge(options))
    false
  end

  def render_500(options = {})
    message = t(:notice_internal_server_error, app_title: Setting.app_title)

    if $ERROR_INFO.is_a?(ActionView::ActionViewError)
      @template.instance_variable_set('@project', nil)
      @template.instance_variable_set('@status', 500)
      @template.instance_variable_set('@message', message)
    else
      @project = nil
    end

    render_error({ message: message }.merge(options))
    false
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
    arg = { message: arg } unless arg.is_a?(Hash)

    @message = arg[:message]
    @message = l(@message) if @message.is_a?(Symbol)
    @status = arg[:status] || 500

    respond_to do |format|
      format.html do
        render template: 'common/error', layout: use_layout, status: @status
      end
      format.any(:atom, :xml, :js, :json, :pdf, :csv) do
        head @status
      end
    end
  end

  # Picks which layout to use based on the request
  #
  # @return [boolean, string] name of the layout to use or false for no layout
  def use_layout
    request.xhr? ? false : 'base'
  end

  def render_feed(items, options = {})
    @items = items || []
    @items = @items.sort { |x, y| y.event_datetime <=> x.event_datetime }
    @items = @items.slice(0, Setting.feeds_limit.to_i)
    @title = options[:title] || Setting.app_title
    render template: 'common/feed', layout: false, content_type: 'application/atom+xml'
  end

  def self.accept_key_auth(*actions)
    actions = actions.flatten.map(&:to_s)
    self.accept_key_auth_actions = actions
  end

  def accept_key_auth_actions
    self.class.accept_key_auth_actions || []
  end

  # Returns a string that can be used as filename value in Content-Disposition header
  def filename_for_content_disposition(name)
    request.env['HTTP_USER_AGENT'] =~ %r{(MSIE|Trident)} ? ERB::Util.url_encode(name) : name
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
    elsif request.headers['X-OpenProject-API-Key'].present?
      request.headers['X-OpenProject-API-Key']
    end
  end

  # Renders a warning flash if obj has unsaved attachments
  def render_attachment_warning_if_needed(obj)
    if obj.unsaved_attachments.present?
      flash[:warning] = l(:warning_attachments_not_saved, obj.unsaved_attachments.size)
    end
  end

  # Rescues an invalid query statement. Just in case...
  def query_statement_invalid(exception)
    logger.error "Query::StatementInvalid: #{exception.message}" if logger
    session.delete(:query)
    sort_clear if respond_to?(:sort_clear)
    render_error 'An error occurred while executing the query and has been logged. ' \
                 'Please report this error to your administrator.'
  end

  # Converts the errors on an ActiveRecord object into a common JSON format
  def object_errors_to_json(object)
    object.errors.map { |attribute, error|
      { attribute => error }
    }.to_json
  end

  # Renders API response on validation failure
  def render_validation_errors(object)
    options = { status: :unprocessable_entity, layout: false }
    errors = case params[:format]
             when 'xml'
               { xml:  object.errors }
             when 'json'
               { json: { 'errors' => object.errors } } # ActiveResource client compliance
             else
               fail "Unknown format #{params[:format]} in #render_validation_errors"
             end
    options.merge! errors
    render options
  end

  # Overrides #default_template so that the api template
  # is used automatically if it exists
  def default_template(action_name = self.action_name)
    if api_request?
      begin
        return view_paths.find_template(default_template_name(action_name), 'api')
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
    name = l('label_' + self.class.name.gsub('Controller', '').underscore.singularize + '_plural')
    if name =~ /translation missing/i
      name = l('label_' + self.class.name.gsub('Controller', '').underscore.singularize)
    end
    name
  end
  helper_method :default_breadcrumb

  def show_local_breadcrumb
    false
  end
  helper_method :show_local_breadcrumb

  def disable_everything_except_api
    unless api_request?
      head 410
      return false
    end
    true
  end

  def disable_api
    # Changing this to not use api_request? to determine whether a request is an API
    # request can have security implications regarding CSRF. See handle_unverified_request
    # for more information.
    if api_request?
      head 410
      return false
    end
    true
  end

  def check_session_lifetime
    if session_expired?
      self.logged_user = nil

      flash[:warning] = I18n.t('notice_forced_logout', ttl_time: Setting.session_ttl)
      redirect_to(controller: 'account', action: 'login', back_url: login_back_url)
    end
    session[:updated_at] = Time.now
  end

  def feed_request?
    if params[:format].nil?
      %w(application/rss+xml application/atom+xml).include? request.format.to_s
    else
      %w(atom rss).include? params[:format]
    end
  end

  def stop_if_feeds_disabled
    if feed_request? && !Setting.feeds_enabled?
      render_404(message: I18n.t('label_disabled'))
    end
  end

  private

  def session_expired?
    !api_request? && current_user.logged? && session_ttl_expired?
  end

  def permitted_params
    @permitted_params ||= PermittedParams.new(params, current_user)
  end

  def login_back_url_params
    {}
  end

  def login_back_url
    # Extract only the basic url parameters on non-GET requests
    if request.get?
      # rely on url_for to fill in the parameters of the current request
      url_for(login_back_url_params)
    else
      url_params = params.permit(:action, :id, :project_id, :controller)

      unless url_params[:controller].to_s.starts_with?('/')
        url_params[:controller] = "/#{url_params[:controller]}"
      end

      url_for(url_params)
    end
  end

  # ActiveSupport load hooks provide plugins with a consistent entry point to patch core classes.
  # They should be called at the very end of a class definition or file,
  # so plugins can be sure everything has been loaded. This load hook allows plugins to register
  # callbacks when the core application controller is fully loaded. Good explanation of load hooks:
  # http://simonecarletti.com/blog/2011/04/understanding-ruby-and-rails-lazy-load-hooks/
  ActiveSupport.run_load_hooks(:application_controller, self)
end
