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

  # Return current logged in user or nil
  def loggedin?
    @logged_in_user
  end
  
  # Return true if user is logged in and is admin, otherwise false
  def admin_loggedin?
    @logged_in_user and @logged_in_user.admin?
  end

  # Return true if user is authorized for controller/action, otherwise false
  def authorize_for(controller, action)  
    # check if action is allowed on public projects
    if @project.is_public? and Permission.allowed_to_public "%s/%s" % [ controller, action ]
      return true
    end
    # check if user is authorized    
    if @logged_in_user and (@logged_in_user.admin? or Permission.allowed_to_role( "%s/%s" % [ controller, action ], @logged_in_user.role_for_project(@project.id)  )  )
      return true
    end
    return false
  end

  # Display a link if user is authorized
  def link_to_if_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to(name, options, html_options, *parameters_for_method_reference) if authorize_for(options[:controller], options[:action])
  end

  # Display a link to user's account page
  def link_to_user(user)
    link_to user.display_name, :controller => 'account', :action => 'show', :id => user
  end

  def format_date(date)
    l_date(date) if date
  end
  
  def format_time(time)
    l_datetime(time) if time
  end
  
  def pagination_links_full(paginator, options={}, html_options={})
    html =''
    html << link_to(('&#171; ' + l(:label_previous) ), { :page => paginator.current.previous }) + ' ' if paginator.current.previous
    html << (pagination_links(paginator, options, html_options) || '')
    html << ' ' + link_to((l(:label_next) + ' &#187;'), { :page => paginator.current.next }) if paginator.current.next
    html  
  end
  
  def error_messages_for(object_name, options = {})
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}")
    if object && !object.errors.empty?
      # build full_messages here with controller current language
      full_messages = []
      object.errors.each do |attr, msg|
        next if msg.nil?
        if attr == "base"
          full_messages << l(msg)
        else
          full_messages << "&#171; " + (l_has_string?("field_" + attr) ? l("field_" + attr) : object.class.human_attribute_name(attr)) + " &#187; " + l(msg) unless attr == "custom_values"
        end
      end
      # retrieve custom values error messages
      if object.errors[:custom_values]
        object.custom_values.each do |v| 
          v.errors.each do |attr, msg|
            next if msg.nil?
            full_messages << "&#171; " + v.custom_field.name + " &#187; " + l(msg)
          end
        end
      end      
      content_tag("div",
        content_tag(
          options[:header_tag] || "h2", lwr(:gui_validation_error, full_messages.length) + " :"
        ) +
        content_tag("ul", full_messages.collect { |msg| content_tag("li", msg) }),
        "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
      )
    else
      ""
    end
  end
  
  def lang_options_for_select
    (GLoc.valid_languages.sort {|x,y| x.to_s <=> y.to_s }).collect {|lang| [ l_lang_name(lang.to_s, lang), lang.to_s]}
  end
end
