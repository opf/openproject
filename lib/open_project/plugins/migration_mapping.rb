#-- copyright
# OpenProject Plugins Plugin
#
# Copyright (C) 2013 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++
module OpenProject::Plugins
  module MigrationMapping
    def self.migration_files_to_migration_names(migration_files, old_plugin_name)
      migration_files.split.map do |m|
        #take only the version number without leading zeroes and concatenate it with the old plugin name
        m.to_i.to_s + "-" + old_plugin_name
      end
    end
  end
end
