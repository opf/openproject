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

module WatchersHelper

  # Valid options
  # * :id - the element id
  # * :replace - a string or array of element ids that will be
  #   replaced
  def watcher_tag(object, user, options={:replace => 'watcher'})
    id = options[:id]
    id ||= options[:replace] if options[:replace].is_a? String
    content_tag("span", watcher_link(object, user, options), :id => id)
  end
  
  # Valid options
  # * :replace - a string or array of element ids that will be
  #   replaced
  def watcher_link(object, user, options={:replace => 'watcher'})
    return '' unless user && user.logged? && object.respond_to?('watched_by?')
    watched = object.watched_by?(user)
    url = {:controller => 'watchers',
           :action => (watched ? 'unwatch' : 'watch'),
           :object_type => object.class.to_s.underscore,
           :object_id => object.id,
           :replace => options[:replace]}
    link_to_remote((watched ? l(:button_unwatch) : l(:button_watch)),
                   {:url => url},
                   :href => url_for(url),
                   :class => (watched ? 'icon icon-fav' : 'icon icon-fav-off'))
  
  end
  
  # Returns a comma separated list of users watching the given object
  def watchers_list(object)
    remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
    lis = object.watcher_users.collect do |user|
      s = avatar(user, :size => "16").to_s + link_to_user(user, :class => 'user').to_s
      if remove_allowed
        url = {:controller => 'watchers',
               :action => 'destroy',
               :object_type => object.class.to_s.underscore,
               :object_id => object.id,
               :user_id => user}
        s += ' ' + link_to_remote(image_tag('delete.png'),
                                  {:url => url},
                                  :href => url_for(url),
                                  :style => "vertical-align: middle",
                                  :class => "delete")
      end
      "<li>#{ s }</li>"
    end
    lis.empty? ? "" : "<ul>#{ lis.join("\n") }</ul>"
  end
end
