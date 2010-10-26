# The engines plugin makes it trivial to share public assets using plugins. 
# To do this, include an <tt>assets</tt> directory within your plugin, and put
# your javascripts, stylesheets and images in subdirectories of that folder:
#
#   my_plugin
#     |- init.rb
#     |- lib/
#     |- assets/
#          |- javascripts/
#          |    |- my_functions.js
#          |
#          |- stylesheets/
#          |    |- my_styles.css
#          |
#          |- images/
#               |- my_face.jpg
#
# Files within the <tt>asset</tt> structure are automatically mirrored into
# a publicly-accessible folder each time your application starts (see
# Engines::Assets#mirror_assets).
#
#
# == Using plugin assets in views
#
# It's also simple to use Rails' helpers in your views to use plugin assets.
# The default helper methods have been enhanced by the engines plugin to accept
# a <tt>:plugin</tt> option, indicating the plugin containing the desired asset.
#
# For example, it's easy to use plugin assets in your layouts:
#
#   <%= stylesheet_link_tag "my_styles", :plugin => "my_plugin", :media => "screen" %>
#   <%= javascript_include_tag "my_functions", :plugin => "my_plugin" %>
# 
# ... and similarly in views and partials, it's easy to use plugin images:
#
#   <%= image_tag "my_face", :plugin => "my_plugin" %>
#   <!-- or -->
#   <%= image_path "my_face", :plugin => "my_plugin" %>
#
# Where the default helpers allow the specification of more than one file (i.e. the
# javascript and stylesheet helpers), you can do similarly for multiple assets from 
# within a single plugin.
#
# ---
#
# This module enhances four of the methods from ActionView::Helpers::AssetTagHelper:
#
#  * stylesheet_link_tag
#  * javascript_include_tag
#  * image_path
#  * image_tag
#
# Each one of these methods now accepts the key/value pair <tt>:plugin => "plugin_name"</tt>,
# which can be used to specify the originating plugin for any assets.
#
module Engines::RailsExtensions::AssetHelpers
  def self.included(base) #:nodoc:
    base.class_eval do
      [:stylesheet_link_tag, :javascript_include_tag, :image_path, :image_tag].each do |m|
        alias_method_chain m, :engine_additions
      end
    end
  end

  # Adds plugin functionality to Rails' default stylesheet_link_tag method.
  def stylesheet_link_tag_with_engine_additions(*sources)
    stylesheet_link_tag_without_engine_additions(*Engines::RailsExtensions::AssetHelpers.pluginify_sources("stylesheets", *sources))
  end

  # Adds plugin functionality to Rails' default javascript_include_tag method.  
  def javascript_include_tag_with_engine_additions(*sources)
    javascript_include_tag_without_engine_additions(*Engines::RailsExtensions::AssetHelpers.pluginify_sources("javascripts", *sources))
  end

  #--
  # Our modified image_path now takes a 'plugin' option, though it doesn't require it
  #++

  # Adds plugin functionality to Rails' default image_path method.
  def image_path_with_engine_additions(source, options={})
    options.stringify_keys!
    source = Engines::RailsExtensions::AssetHelpers.plugin_asset_path(options["plugin"], "images", source) if options["plugin"]
    image_path_without_engine_additions(source)
  end

  # Adds plugin functionality to Rails' default image_tag method.
  def image_tag_with_engine_additions(source, options={})
    options.stringify_keys!
    if options["plugin"]
      source = Engines::RailsExtensions::AssetHelpers.plugin_asset_path(options["plugin"], "images", source)
      options.delete("plugin")
    end
    image_tag_without_engine_additions(source, options)
  end

  #--
  # The following are methods on this module directly because of the weird-freaky way
  # Rails creates the helper instance that views actually get
  #++

  # Convert sources to the paths for the given plugin, if any plugin option is given
  def self.pluginify_sources(type, *sources)
    options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
    sources.map! { |s| plugin_asset_path(options["plugin"], type, s) } if options["plugin"]
    options.delete("plugin") # we don't want it appearing in the HTML
    sources << options # re-add options      
  end  

  # Returns the publicly-addressable relative URI for the given asset, type and plugin
  def self.plugin_asset_path(plugin_name, type, asset)
    raise "No plugin called '#{plugin_name}' - please use the full name of a loaded plugin." if Engines.plugins[plugin_name].nil?
    "#{ActionController::Base.relative_url_root}/#{Engines.plugins[plugin_name].public_asset_directory}/#{type}/#{asset}"
  end
  
end

module ::ActionView::Helpers::AssetTagHelper #:nodoc:
  include Engines::RailsExtensions::AssetHelpers
end
