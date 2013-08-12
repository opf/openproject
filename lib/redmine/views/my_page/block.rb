#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module Views
    module MyPage
      module Block

        def self.additional_blocks
          #look at the gemspecs of all plugins trying to find views in a /my/blocks subdirectory
          @@additional_blocks ||= Dir.glob(
            Plugin.registered_plugins.map do |plugin_id,_|
              gem_spec = Gem.loaded_specs[plugin_id.to_s]
              if gem_spec.nil?
                ActiveSupport::Deprecation.warn "No Gemspec found for plugin: " + plugin_id.to_s + ", plugin name should equal the gem name"
                nil
              else
                Gem.loaded_specs[plugin_id.to_s].full_gem_path + '/**/my/blocks/_*.{rhtml,erb}'
              end
            end.compact
          ).inject({}) do |h,file|
            name = File.basename(file).split('.').first.gsub(/^_/, '')
            h[name] = name.to_sym
            h
          end
        end
      end
    end
  end
end
