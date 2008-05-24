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

module UsersHelper
  def status_options_for_select(selected)
    options_for_select([[l(:label_all), ''], 
                        [l(:status_active), 1],
                        [l(:status_registered), 2],
                        [l(:status_locked), 3]], selected)
  end
  
  # Options for the new membership projects combo-box
  def projects_options_for_select(projects)
    options = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---")
    projects_by_root = projects.group_by(&:root)
    projects_by_root.keys.sort.each do |root|
      options << content_tag('option', h(root.name), :value => root.id, :disabled => (!projects.include?(root)))
      projects_by_root[root].sort.each do |project|
        next if project == root
        options << content_tag('option', '&#187; ' + h(project.name), :value => project.id)
      end
    end
    options
  end
  
  def change_status_link(user)
    url = {:action => 'edit', :id => user, :page => params[:page], :status => params[:status]}
    
    if user.locked?
      link_to l(:button_unlock), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :post, :class => 'icon icon-unlock'
    elsif user.registered?
      link_to l(:button_activate), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :post, :class => 'icon icon-unlock'
    elsif user != User.current
      link_to l(:button_lock), url.merge(:user => {:status => User::STATUS_LOCKED}), :method => :post, :class => 'icon icon-lock'
    end
  end
  
  def user_settings_tabs
    tabs = [{:name => 'general', :partial => 'users/general', :label => :label_general},
            {:name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural}
            ]
  end
end
