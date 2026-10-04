# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Loads two files automatically from plugins:
#
# 1. `spec/disable_specs.rbs` to disable specs which don't work in conjunction with the
# respective plugin.
# 2. The config spec helper in `spec/config_spec_helper` makes sure that the core specs
# (and other plugins' specs) keep working with this plugin in an OpenProject configuration
# even if it changes things which would otherwise break existing specs.
Rails.application.config.plugins_to_test_paths.each do |dir|
  ["disabled_specs.rb", "disable_specs.rb", "config_spec_helper.rb"].each do |file_name|
    file = File.join(dir, "spec", file_name)

    if File.exist?(file)
      puts "Loading #{file}"
      require file
    end
  end
end
