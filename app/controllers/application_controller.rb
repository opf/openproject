# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "uri"
require "cgi"

require "doorkeeper/dashboard_helper"

class ApplicationController < ActionController::Base
  class_attribute :_model_scope
  class_attribute :accept_key_auth_actions

  helper_method :render_to_string
  helper_method :gon

  protected

  include I18n
  include Redmine::I18n
  include HookHelper
  include ErrorsHelper
  include Accounts::CurrentUser
  include Accounts::UserLogin
  include Accounts::Authorization
  include Accounts::EnterpriseGuard
  include ::OpenProject::Authentication::SessionExpiration
  include AdditionalUrlHelpers
  include OpenProjectErrorHelper
  include Security::DefaultUrlOptions
  include OpModalFlashable
  include DynamicContentSecurityPolicy

  layout "base"

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
    cookies.delete(OpenProject::Configuration["autologin_cookie_name"])
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
      message << (" " + I18n.t(:error_cookie_missing)) if openproject_cookie_missing?

      log_csrf_failure

      render_error status: 422, message:
    end
  end

  # Ensure the default handler is listed FIRST
  unless Rails.application.config.consider_all_requests_local
    rescue_from StandardError do |exception|
      render_500 exception:
    end

    rescue_from ActionController::UnknownFormat do
      render body: "406 Not Acceptable: invalid request format",
             status: :not_acceptable
    end
  end

  rescue_from ActionController::ParameterMissing do |exception|
    render body: "Required parameter missing: #{exception.param}",
           status: :bad_request
  end

  rescue_from ActiveRecord::ConnectionTimeoutError do |exception|
    render_500 exception:,
               payload: ::OpenProject::Logging::ThreadPoolContextBuilder.build!
  end

  rescue_from ActiveRecord::RecordNotFound do
    render_404
  end

  before_action :authorization_check_required,
                :user_setup,
                :set_localization,
                :tag_request,
                :check_if_login_required,
                :log_requesting_user,
                :check_session_lifetime,
                :stop_if_feeds_disabled,
                :set_cache_buster,
                :action_hooks,
                :reload_mailer_settings!

  include Redmine::Search::Controller
  include Redmine::MenuManager::MenuController

  helper Redmine::MenuManager::MenuHelper

  # set http headers so that the browser does not store any
  # data (caches) of this site
  # see:
  # https://websecuritytool.codeplex.com/wikipage?title=Checks#http-cache-control-header-no-store
  # http://stackoverflow.com/questions/711418/how-to-prevent-browser-page-caching-in-rails
  def set_cache_buster
    if OpenProject::Configuration["disable_browser_cache"]
      response.cache_control.merge!(
        max_age: 0,
        public: false,
        must_revalidate: true
      )
    end
  end

  def tag_request
    context = { controller: self, request: }
    ::OpenProject::Appsignal.tag_request(context)
    ::OpenProject::OpenTelemetry.tag_request(context)
  end

  def reload_mailer_settings!
    Setting.reload_mailer_settings!
  end

  # Checks if the session cookie is missing.
  # This is useful only on a second request
  def openproject_cookie_missing?
    request.cookies[OpenProject::Configuration["session_cookie_name"]].nil?
  end

  helper_method :openproject_cookie_missing?

  ##
  # Create CSRF issue
  def log_csrf_failure
    message = "CSRF validation error"
    message += " (No session cookie present)" if openproject_cookie_missing?

    op_handle_error message, reference: :csrf_validation_failed
  end

  def log_requesting_user
    return unless Setting.log_requesting_user?

    unless User.current.anonymous?
      login_and_mail = " (#{escape_for_logging(User.current.login)} ID: #{User.current.id} " \
                       "<#{escape_for_logging(User.current.mail)}>)"
    end
    logger.info "OpenProject User: #{escape_for_logging(User.current.name)}#{login_and_mail}"
  end

  # Escape string to prevent log injection
  # e.g. setting the user name to contain \r allows overwriting a log line on console
  # replaces all invalid characters with #
  def escape_for_logging(string)
    # only allow numbers, ASCII letters, space and the following characters: @.-"'!?=/
    string.gsub(/[^0-9a-zA-Z@._\-"'!?=\/ ]{1}/, "#")
  end

  def set_localization
    # 1. Use completely authenticated user
    # 2. Use user with some authenticated stages not completed.
    #    In this case user is not considered logged in, but identified.
    #    It covers localization for extra authentication stages(like :consent, for example)
    # 3. Use anonymous instance.
    user = RequestStore[:current_user] ||
           (session[:authenticated_user_id].present? && User.find_by(id: session[:authenticated_user_id])) ||
           User.anonymous
    SetLocalizationService.new(user, request.env["HTTP_ACCEPT_LANGUAGE"]).call
  end

  def deny_access(not_found: false)
    if User.current.logged?
      not_found ? render_404 : render_403
    else
      require_login
    end
  end

  # Find project of id params[:id]
  # Note: find() is Project.friendly.find()
  def find_project
    @project = Project.visible.find(params[:id])
  end

  # Find project of id params[:project_id]
  # Note: find() is Project.friendly.find()
  def find_project_by_project_id
    @project = Project.visible.find(params[:project_id])
  end

  # Find project by project_id if given
  def find_optional_project
    @project = Project.visible.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds and sets @project based on @object.project
  def find_project_from_association
    render_404 if @object.blank?

    @project = @object.project
  end

  # Filter for bulk work package operations. Either :work_package_id (single-WP
  # routes) or :ids (bulk routes) may carry numeric or semantic identifiers
  # ("PROJ-42") since both originate from human-facing URLs or forms.
  def find_work_packages
    @work_packages = WorkPackage.where_display_id_in(params[:work_package_id] || params[:ids])
                                .includes(:project)
                                .order("id ASC")
    fail ActiveRecord::RecordNotFound if @work_packages.empty?

    @projects = @work_packages.filter_map(&:project).uniq
    @project = @projects.first if @projects.size == 1
  end

  def back_url
    params[:back_url] || request.env["HTTP_REFERER"]
  end

  def redirect_back_or_default(default, use_escaped: true, status: :found)
    policy = RedirectPolicy.new(
      params[:back_url],
      hostname: request.host,
      default:,
      return_escaped: use_escaped
    )

    redirect_to(policy.redirect_url, status:)
  end

  # Picks which layout to use based on the request
  #
  # @return [boolean, string] name of the layout to use or false for no layout
  def use_layout
    request.xhr? ? false : "no_menu"
  end

  def render_feed(items, options = {})
    @items = items || []
    @items = @items.sort { |x, y| y.event_datetime <=> x.event_datetime }
    @items = @items.slice(0, Setting.feeds_limit.to_i)
    @title = options[:title] || Setting.app_title
    render template: "common/feed", layout: false, content_type: "application/atom+xml"
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
    %r{(MSIE|Trident)}.match?(request.env["HTTP_USER_AGENT"]) ? ERB::Util.url_encode(name) : name
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

  # Converts the errors on an ActiveRecord object into a common JSON format
  def object_errors_to_json(object)
    object.errors.map do |attribute, error|
      { attribute => error }
    end.to_json
  end

  # Renders API response on validation failure
  def render_validation_errors(object)
    options = { status: :unprocessable_entity, layout: false }
    errors = case params[:format]
             when "xml"
               { xml: object.errors }
             when "json"
               { json: { "errors" => object.errors } } # ActiveResource client compliance
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
        return view_paths.find_template(default_template_name(action_name), "api")
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

  def admin_first_level_menu_entry
    menu_item = admin_menu_item(current_menu_item)
    menu_item.parent
  end

  helper_method :admin_first_level_menu_entry

  def check_session_lifetime
    if session_expired?
      self.logged_user = nil

      flash[:warning] = I18n.t("notice_forced_logout", ttl_time: Setting.session_ttl)
      redirect_to(controller: "/account", action: "login", back_url: login_back_url)
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
      render_404(message: I18n.t("label_disabled"))
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

      unless url_params[:controller].to_s.starts_with?("/")
        url_params[:controller] = "/#{url_params[:controller]}"
      end

      url_for(url_params)
    end
  end

  def action_hooks
    call_hook(:application_controller_before_action)
  end

  # ActiveSupport load hooks provide plugins with a consistent entry point to patch core classes.
  # They should be called at the very end of a class definition or file,
  # so plugins can be sure everything has been loaded. This load hook allows plugins to register
  # callbacks when the core application controller is fully loaded. Good explanation of load hooks:
  # http://simonecarletti.com/blog/2011/04/understanding-ruby-and-rails-lazy-load-hooks/
  ActiveSupport.run_load_hooks(:application_controller, self)

  prepend AuthSourceSSO
end
