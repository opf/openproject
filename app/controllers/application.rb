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

class ApplicationController < ActionController::Base
  before_filter :user_setup, :check_if_login_required, :set_localization
  filter_parameter_logging :password
  
  REDMINE_SUPPORTED_SCM.each do |scm|
    require_dependency "repository/#{scm.underscore}"
  end
  
  def current_role
    @current_role ||= User.current.role_for_project(@project)
  end
  
  def user_setup
    Setting.check_cache
    if session[:user_id]
      # existing session
      User.current = User.find(session[:user_id])
    elsif cookies[:autologin] && Setting.autologin?
      # auto-login feature
      User.current = User.find_by_autologin_key(cookies[:autologin])
    elsif params[:key] && accept_key_auth_actions.include?(params[:action])
      # RSS key authentication
      User.current = User.find_by_rss_key(params[:key])
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
    lang = begin
      if !User.current.language.blank? and GLoc.valid_languages.include? User.current.language.to_sym
        User.current.language
      elsif request.env['HTTP_ACCEPT_LANGUAGE']
        accept_lang = parse_qvalues(request.env['HTTP_ACCEPT_LANGUAGE']).first.split('-').first
        if accept_lang and !accept_lang.empty? and GLoc.valid_languages.include? accept_lang.to_sym
          accept_lang
        end
      end
    rescue
      nil
    end || Setting.default_language
    set_language_if_valid(lang)    
  end
  
  def require_login
    if !User.current.logged?
      store_location
      redirect_to :controller => "account", :action => "login"
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

  # Authorize the user for the requested action
  def authorize(ctrl = params[:controller], action = params[:action])
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project)
    allowed ? true : (User.current.logged? ? render_403 : require_login)
  end
  
  # make sure that the user is a member of the project (or admin) if project is private
  # used as a before_filter for actions that do not require any particular permission on the project
  def check_project_privacy
    unless @project.active?
      @project = nil
      render_404
      return false
    end
    return true if @project.is_public? || User.current.member_of?(@project) || User.current.admin?
    User.current.logged? ? render_403 : require_login
  end

  # store current uri in session.
  # return to this location by calling redirect_back_or_default
  def store_location
    session[:return_to_params] = params
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to_params].nil?
      redirect_to default
    else
      redirect_to session[:return_to_params]
      session[:return_to_params] = nil
    end
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
  
  def render_feed(items, options={})    
    @items = items || []
    @items.sort! {|x,y| y.event_datetime <=> x.event_datetime }
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
  def attach_files(obj, files)
    attachments = []
    if files && files.is_a?(Array)
      files.each do |file|
        next unless file.size > 0
        a = Attachment.create(:container => obj, :file => file, :author => User.current)
        attachments << a unless a.new_record?
      end
    end
    attachments
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
  end
end
