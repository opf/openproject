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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

namespace :setting do
  desc "Allow to set a Setting: rake setting:set[key1=value1,key2=value2]"
  task set: :environment do |_t, args|
    args.extras.each do |tuple|
      key, value = tuple.split("=")
      setting = Setting.find_or_initialize_by(name: key)
      setting.set_value! value, force: true
      setting.save!
    end
  end

  desc "Allow to get a Setting: rake setting:get[key]"
  task :get, [:key] => :environment do |_t, args|
    setting = Setting.find_by(name: args[:key])
    unless setting.nil?
      puts(setting.value)
    end
  end

  desc "Allow to set a Setting read from an ENV var. Example: rake setting:set_to_env[smtp_address=SMTP_HOST]"
  task set_to_env: :environment do |_t, args|
    args.extras.each do |tuple|
      setting_name, env_var_name = tuple.split("=")

      next unless Settings::Definition.exists? setting_name
      next unless ENV.has_key? env_var_name

      setting = Setting.find_or_initialize_by(name: setting_name)
      setting.set_value! ENV[env_var_name].presence, force: true
      setting.save!
    end
  end

  desc "List the supported environment variables to override settings"
  task available_envs: :environment do
    Settings::Definition.all.sort.each do |_name, definition|
      puts "#{Settings::Definition.possible_env_names(definition).first} " \
           "(default=#{definition.default.inspect}) #{definition.description}"
    end
  end
end
