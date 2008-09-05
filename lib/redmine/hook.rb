# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

module Redmine
  module Hook
    @@listener_classes = []
    @@listeners = nil
    @@hook_listeners = {}
    
    class << self
      # Adds a listener class.
      # Automatically called when a class inherits from Redmine::Hook::Listener.
      def add_listener(klass)
        raise "Hooks must include Singleton module." unless klass.included_modules.include?(Singleton)
        @@listener_classes << klass
        clear_listeners_instances
      end
      
      # Returns all the listerners instances.
      def listeners
        @@listeners ||= @@listener_classes.collect {|listener| listener.instance}
      end
 
      # Returns the listeners instances for the given hook.
      def hook_listeners(hook)
        @@hook_listeners[hook] ||= listeners.select {|listener| listener.respond_to?(hook)}
      end
      
      # Clears all the listeners.
      def clear_listeners
        @@listener_classes = []
        clear_listeners_instances
      end
      
      # Clears all the listeners instances.
      def clear_listeners_instances
        @@listeners = nil
        @@hook_listeners = {}
      end
      
      # Calls a hook.
      # Returns the listeners response.
      def call_hook(hook, context={})
        response = ''
        hook_listeners(hook).each do |listener|
          response << listener.send(hook, context).to_s
        end
        response
      end
    end

    # Base class for hook listeners.
    class Listener
      include Singleton

      # Registers the listener
      def self.inherited(child)
        Redmine::Hook.add_listener(child)
        super
      end
    end
    
    # Listener class used for views hooks.
    # Listeners that inherit this class will include various helpers by default.
    class ViewListener < Listener
      include ERB::Util
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::FormOptionsHelper
      include ActionView::Helpers::JavaScriptHelper
      include ActionView::Helpers::PrototypeHelper
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::AssetTagHelper
      include ActionView::Helpers::TextHelper
      include ActionController::UrlWriter
      include ApplicationHelper
    end

    # Helper module included in ApplicationHelper so that hooks can be called
    # in views like this:
    #   <%= call_hook(:some_hook) %>
    #   <%= call_hook(:another_hook, :foo => 'bar' %>
    # 
    # Current project is automatically added to the call context.
    module Helper
      def call_hook(hook, context={})
        Redmine::Hook.call_hook(hook, {:project => @project}.merge(context))
      end
    end
  end
end

ApplicationHelper.send(:include, Redmine::Hook::Helper)
