#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

module Redmine
  module Views
    module MyPage
      module Block
        def self.additional_blocks
          # look at the gemspecs of all plugins trying to find views in a /my/blocks subdirectory
          @@additional_blocks ||= Dir.glob(
            Plugin.registered_plugins.map do |plugin_id, _|
              gem_name = plugin_id.to_s.gsub('openproject_', 'openproject-') if plugin_id.to_s.starts_with?('openproject_')
              gem_spec = Gem.loaded_specs[gem_name]
              if gem_spec.nil?
                error = 'No Gemspec found for plugin: ' + plugin_id.to_s \
                + ', expected gem name to match the plugin name but starting with openproject-'
                ActiveSupport::Deprecation.warn(error)
                nil
              else
                gem_spec.full_gem_path + '/app/views/my/blocks/_*.{rhtml,erb}'
              end
            end.compact
          ).inject({}) do |h, file|
            name = File.basename(file).split('.').first.gsub(/\A_/, '')
            h[name] = ('label_' + name).to_sym
            h
          end
        end
      end
    end
  end
end
