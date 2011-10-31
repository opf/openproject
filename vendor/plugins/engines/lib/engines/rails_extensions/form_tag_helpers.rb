#-- encoding: UTF-8
# == Using plugin assets for form tag helpers
#
# It's as easy to use plugin images for image_submit_tag using Engines as it is for image_tag:
#
#   <%= image_submit_tag "my_face", :plugin => "my_plugin" %>
#
# ---
#
# This module enhances one of the methods from ActionView::Helpers::FormTagHelper:
#
#  * image_submit_tag
#
# This method now accepts the key/value pair <tt>:plugin => "plugin_name"</tt>,
# which can be used to specify the originating plugin for any assets.
#
module Engines::RailsExtensions::FormTagHelpers
	def self.included(base)
		base.class_eval do
			alias_method_chain :image_submit_tag, :engine_additions
		end
	end
	
	# Adds plugin functionality to Rails' default image_submit_tag method.
	def image_submit_tag_with_engine_additions(source, options={})
		options.stringify_keys!
		if options["plugin"]
			source = Engines::RailsExtensions::AssetHelpers.plugin_asset_path(options["plugin"], "images", source)
			options.delete("plugin")
		end
		image_submit_tag_without_engine_additions(source, options)
	end
end

module ::ActionView::Helpers::FormTagHelper #:nodoc:
  include Engines::RailsExtensions::FormTagHelpers
end

