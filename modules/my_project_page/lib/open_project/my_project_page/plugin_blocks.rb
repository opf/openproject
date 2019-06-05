#-- encoding: UTF-8
#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++


module OpenProject
  module MyProjectPage
    # This method loads additional blocks for the myproject-page from registered pugins
    def self.plugin_blocks
      #look at the gemspecs of all plugins trying to find views in a /my_project_page/blocks subdirectory
      @@additional_blocks ||= Dir.glob(
        Redmine::Plugin.registered_plugins.map do |plugin_id,_|
          gem_name = plugin_id.to_s.gsub('openproject_','openproject-') if plugin_id.to_s.starts_with?('openproject_')
          gem_spec = Gem.loaded_specs[gem_name]
          if gem_spec.nil?
            error = "No Gemspec found for plugin: " + plugin_id.to_s \
              + ", expected gem name to match the plugin name but starting with openproject-"
            ActiveSupport::Deprecation.warn(error)
            nil
          else
            gem_spec.full_gem_path + '/app/views/my_projects_overviews/blocks/_*.{rhtml,erb}'
          end
        end.compact
      ).inject({}) do |h,file|
        name = File.basename(file).split('.').first.gsub(/^_/, '')
        h[name] = ("label_"+ name).to_sym
        h
      end
    end
  end
end
