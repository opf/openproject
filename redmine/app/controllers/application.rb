# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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
  before_filter :check_if_login_required, :set_localization
  
  # check if login is globally required to access the application
  def check_if_login_required
    require_login if RDM_LOGIN_REQUIRED
  end 
  
  def set_localization
    Localization.lang = begin
      if session[:user]
        session[:user].language
      elsif request.env['HTTP_ACCEPT_LANGUAGE']
        accept_lang = HTTPUtils.parse_qvalues(request.env['HTTP_ACCEPT_LANGUAGE']).first.split('-').first
        if Localization.langs.collect{ |l| l[1] }.include? accept_lang
          accept_lang
        end
      end
    rescue
      nil
    end || RDM_DEFAULT_LANG
  end
  
  def require_login
    unless session[:user]
      store_location
      redirect_to(:controller => "account", :action => "login")
    end
  end

  def require_admin
    if session[:user].nil?
      store_location
      redirect_to(:controller => "account", :action => "login")
    else
      unless session[:user].admin?
        flash[:notice] = "Acces not allowed"
        redirect_to(:controller => "projects", :action => "list")
      end
    end
  end

  # authorizes the user for the requested action.
  def authorize
    # check if action is allowed on public projects
    if @project.is_public? and Permission.allowed_to_public "%s/%s" % [ @params[:controller], @params[:action] ]
      return true
    end  
    # if user not logged in, redirect to login form
    unless session[:user]
      store_location
      redirect_to(:controller => "account", :action => "login")
      return false
    end
    # if logged in, check if authorized    
    if session[:user].admin? or Permission.allowed_to_role( "%s/%s" % [ @params[:controller], @params[:action] ], session[:user].role_for_project(@project.id)  )    
      return true		
    end		
    flash[:notice] = "Acces denied"
    redirect_to(:controller => "")
    false
  end
	
  # store current uri in session.
  # return to this location by calling redirect_back_or_default
  def store_location
    session[:return_to] = @request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to_url session[:return_to]
      session[:return_to] = nil
    end
  end
end