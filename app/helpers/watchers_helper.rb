#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
  def watcher_link(object, user, options = {:replace => '.watcher_link', :class => 'watcher_link'})
    options = options.with_indifferent_access
    raise ArgumentError, 'Missing :replace option in options hash' if options['replace'].blank?

    return '' unless user && user.logged? && object.respond_to?('watched_by?')

    watched = object.watched_by?(user)
    url = {:controller => 'watchers',
           :action => (watched ? 'unwatch' : 'watch'),
           :object_type => object.class.to_s.underscore,
           :object_id => object.id,
           :replace => options.delete('replace')}

    url_options = {:url => url}

    html_options = options.merge(:href => url_for(url))
    html_options[:class] = html_options[:class].to_s + (watched ? ' icon icon-fav' : ' icon icon-fav-off')

    link_to_remote((watched ? l(:button_unwatch) : l(:button_watch)), url_options, html_options)
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
        s += ' ' + link_to_remote(image_tag('delete.png', :alt => l(:button_delete), :title => l(:button_delete)),
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
