#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module WatchersHelper

  # Deprecated method. Use watcher_link instead
  #
  # This method will be removed in ChiliProject 3.0 or later
  def watcher_tag(object, user, options={:replace => 'watcher'})
    ActiveSupport::Deprecation.warn "The WatchersHelper#watcher_tag is deprecated and will be removed in ChiliProject 3.0. Please use WatchersHelper#watcher_link instead. Please also note the differences between the APIs.", caller

    options[:id] ||= options[:replace] if options[:replace].is_a? String

    options[:replace] = Array(options[:replace]).map { |id| "##{id}" }

    watcher_link(object, user, options)
  end

  # Create a link to watch/unwatch object
  #
  # * :replace - a string or array of strings with css selectors that will be updated, whenever the watcher status is changed
  def watcher_link(object, user, options = { :replace => '.watcher_link', :class => 'watcher_link' })
    options = options.with_indifferent_access
    raise ArgumentError, 'Missing :replace option in options hash' if options['replace'].blank?

    return '' unless user && user.logged? && object.respond_to?('watched_by?')

    watched = object.watched_by?(user)

    html_options = options
    path = send(:"#{(watched ? 'unwatch' : 'watch')}_path", :object_type => object.class.to_s.underscore.pluralize,
                                                            :object_id => object.id,
                                                            :replace => options.delete('replace') )
    html_options[:class] = html_options[:class].to_s + (watched ? ' icon icon-fav' : ' icon icon-fav-off')

    method = watched ?
      :delete :
      :post

    label = watched ?
      l(:button_unwatch) :
      l(:button_watch)

    link_to(label, path, html_options.merge(:remote => true, :method => method))
  end

  # Returns HTML for a list of users watching the given object
  def watchers_list(object)
    remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
    lis = object.watchers(true).collect do |watch|
      content_tag :li do
        avatar(watch.user, :size => "16") +
          link_to_user(watch.user, :class => 'user') +
          if remove_allowed
            ' '.html_safe + link_to(image_tag('webalys/red_x.png', :alt => l(:button_delete), :title => l(:button_delete)),
                             watcher_path(watch),
                             :method => :delete,
                             :remote => true,
                             :style => "vertical-align: middle",
                             :class => "delete")
          else
            ''.html_safe
          end
      end
    end
    lis.empty? ? ''.html_safe : content_tag(:ul, lis.reduce(:+))
  end
end
