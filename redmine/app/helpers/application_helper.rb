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

module ApplicationHelper

	def loggedin?
		session[:user]
	end

	def admin_loggedin?
		session[:user] && session[:user].admin
	end
	
	def authorize_for(controller, action)  
    # check if action is allowed on public projects
    if @project.is_public? and Permission.allowed_to_public "%s/%s" % [ controller, action ]
      return true
    end  
    # check if user is authorized    
    if session[:user] and (session[:user].admin? or Permission.allowed_to_role( "%s/%s" % [ controller, action ], session[:user].role_for_project(@project.id)  )  )
			return true
		end		
		return false	  
	end
	
	def link_to_if_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
		link_to(name, options, html_options, *parameters_for_method_reference) if authorize_for(options[:controller], options[:action])
	end
	
	# Display a link to user's account page
	def link_to_user(user)
		link_to user.display_name, :controller => 'account', :action => 'show', :id => user
	end
	
  def format_date(date)
    _('(date)', date) if date
  end
  
  def format_time(time)
    _('(time)', time) if time
  end
  
  def pagination_links_full(paginator, options={}, html_options={})
    html =''
    html << link_to(('&#171; ' + _('Previous') ), { :page => paginator.current.previous }) + ' ' if paginator.current.previous
    html << (pagination_links(paginator, options, html_options) || '')
    html << ' ' + link_to((_('Next') + ' &#187;'), { :page => paginator.current.next }) if paginator.current.next
    html  
  end

end
