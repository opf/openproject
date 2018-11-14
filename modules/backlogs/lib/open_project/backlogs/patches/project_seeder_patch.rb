#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

module OpenProject::Backlogs::Patches::ProjectSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def seed_versions(project, key)
      super

      versions = Array(I18n.t("seeders.demo_data.projects.#{key}")[:versions])
        .map { |data| Version.find_by(name: data[:name]) }
        .compact

      versions.each do |version|
        display = version_settings_display_map[version.name] || VersionSetting::DISPLAY_NONE
        version.version_settings.create! display: display, project: version.project
      end
    end

    ##
    # This relies on the names from the core's `config/locales/en.seeders.yml`.
    def version_settings_display_map
      {
        'Sprint 1'        => VersionSetting::DISPLAY_LEFT,
        'Sprint 2'        => VersionSetting::DISPLAY_LEFT,
        'Bug Backlog'     => VersionSetting::DISPLAY_RIGHT,
        'Product Backlog' => VersionSetting::DISPLAY_RIGHT,
        'Wish List'       => VersionSetting::DISPLAY_RIGHT
      }
    end
  end
end
