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

require 'uri'
require 'cgi'

class ApplicationController < ActionController::Base
  include Redmine::I18n
  
  # In case the cookie store secret changes
  rescue_from CGI::Session::CookieStore::TamperedWithCookie do |exception|
    render :text => 'Your session was invalid and has been reset. Please, reload this page.', :status => 500
  end
  
  layout 'base'
  
  before_filter :user_setup, :check_if_login_required, :set_localization
  filter_parameter_logging :password
  
  include Redmine::MenuManager::MenuController
  helper Redmine::MenuManager::MenuHelper
  
  REDMINE_SUPPORTED_SCM.each do |scm|
    require_dependency "repository/#{scm.underscore}"
  end
  
  def user_setup
    # Check the settings cache for each request
    Setting.check_cache
    # Find the current user
    self.logged_user = find_current_user
  end
  
  # Returns the current user or nil if no user is logged in
  def find_current_user
    if session[:user_id]
      # existing session
      (User.active.find(session[:user_id]) rescue nil)
    elsif cookies[:autologin] && Setting.autologin?
      # auto-login feature
      User.try_to_autologin(cookies[:autologin])
    elsif params[:key] && accept_key_auth_actions.include?(params[:action])
      # RSS key authentication
      User.find_by_rss_key(params[:key])
    end
  end
  
  # Sets the logged in user
  def logged_user=(user)
    if user && user.is_a?(User)
      User.current = user
      session[:user_id] = user.id
    else
      User.current = User.anonymous
      session[:user_id] = nil
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
      accept_lang = parse_qvalues(request.env['HTTP_ACCEPT_LANGUAGE']).first.downcase
      if !accept_lang.blank?
        lang = find_language(accept_lang) || find_language(accept_lang.split('-').first)
      end
    end
    lang ||= Setting.default_language
    set_language_if_valid(lang)
  end
  
  def require_login
    if !User.current.logged?
      redirect_to :controller => "account", :action => "login", :back_url => url_for(params)
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
  def authorize(ctrl = params[:controller], action = params[:action])
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project)
    allowed ? true : deny_access
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

  def redirect_back_or_default(default)
    back_url = CGI.unescape(params[:back_url].to_s)
    if !back_url.blank?
      begin
        uri = URI.parse(back_url)
        # do not redirect user to another host or to the login or register page
        if (uri.relative? || (uri.host == request.host)) && !uri.path.match(%r{/(login|account/register)})
          redirect_to(back_url) and return
        end
      rescue URI::InvalidURIError
        # redirect to default
      end
    end
    redirect_to default
  end
  
  def render_403
    @project = nil
    render :template => "common/403", :layout => !request.xhr?, :status => 403
    return false
  end
    
  def render_404
    render :template => "common/404", :layout => !request.xhr?, :status => 404
    return false
  end
  
  def render_error(msg)
    flash.now[:error] = msg
    render :text => '', :layout => !request.xhr?, :status => 500
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
  
  # TODO: move to model
  def attach_files(obj, attachments)
    attached = []
    unsaved = []
    if attachments && attachments.is_a?(Hash)
      attachments.each_value do |attachment|
        file = attachment['file']
        next unless file && file.size > 0
        a = Attachment.create(:container => obj, 
                              :file => file,
                              :description => attachment['description'].to_s.strip,
                              :author => User.current)
        a.new_record? ? (unsaved << a) : (attached << a)
      end
      if unsaved.any?
        flash[:warning] = l(:warning_attachments_not_saved, unsaved.size)
      end
    end
    attached
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
end
