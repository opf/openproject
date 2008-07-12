# Effective use of Rails' routes can help create a tidy and elegant set of URLs,
# and is a significant part of creating an external API for your web application.
# 
# When developing plugins which contain controllers, it seems obvious that including
# the corresponding routes would be extremely useful. This is particularly true
# when exposing RESTful resources using the new REST-ian features of Rails.
#
# == Including routes in your plugin
#
# The engines plugin makes it possible to include a set of routes within your plugin
# very simply, as it turns out. In your plugin, you simply include a <tt>routes.rb</tt> 
# file like the one below at the root of your plugin:
# 
#   connect "/login", :controller => "my_plugin/account", :action => "login"
#
#   # add a named route
#   logout "/logout", :controller => "my_plugin/account", :action => "logout"
#
#   # some restful stuff
#   resources :things do |t|
#     t.resources :other_things
#   end
# 
# Everywhere in a normal <tt>RAILS_ROOT/config/routes.rb</tt> file 
# where you might have <tt>map.connect</tt>, you just use <tt>connect</tt> in your 
# plugin's <tt>routes.rb</tt>.
# 
# === Hooking it up in your application
#
# While it would be possible to have each plugin's routes automagically included into
# the application's route set, to do so would actually be a stunningly bad idea. Route
# priority is the key issue here. You, the application developer, needs to be in complete
# control when it comes to specifying the priority of routes in your application, since 
# the ordering of your routes directly affects how Rails will interpret incoming requests.
# 
# To add plugin routes into your application's <tt>routes.rb</tt> file, you need to explicitly 
# map them in using the Engines::RailsExtensions::Routing#from_plugin method:
# 
#   ApplicationController::Routing::Routes.draw do |map|
#
#     map.connect "/app_stuff", :controller => "application_thing" # etc...
#
#     # This line includes the routes from the given plugin at this point, giving you
#     # control over the priority of your application routes 
#     map.from_plugin :your_plugin
#
#     map.connect ":controller/:action/:id"
#   end
# 
# By including routes in plugins which have controllers, you can now share in a simple way 
# a compact and elegant URL scheme which corresponds to those controllers.
#
# ---
#
# The Engines::RailsExtensions::Routing module defines extensions to Rails' 
# routing (ActionController::Routing) mechanism such that routes can be loaded 
# from a given plugin.
#
# The key method is Engines::RailsExtensions::Routing#from_plugin, which can be called 
# within your application's <tt>config/routes.rb</tt> file to load plugin routes at that point.
#
module Engines::RailsExtensions::Routing
  # Loads the set of routes from within a plugin and evaluates them at this
  # point within an application's main <tt>routes.rb</tt> file.
  #
  # Plugin routes are loaded from <tt><plugin_root>/routes.rb</tt>.
  def from_plugin(name)
    map = self # to make 'map' available within the plugin route file
    routes_path = Engines.plugins[name].routes_path
    Engines.logger.debug "loading routes from #{routes_path}"
    eval(IO.read(routes_path), binding, routes_path) if File.file?(routes_path)
  end
end

  
module ::ActionController #:nodoc:
  module Routing #:nodoc:
    class RouteSet #:nodoc:
      class Mapper #:nodoc:
        include Engines::RailsExtensions::Routing
      end
    end
  end
end
