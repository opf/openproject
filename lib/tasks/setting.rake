#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

namespace :setting do
  desc 'Allow to set a Setting: rake setting:set[key1=value1,key2=value2]'
  task set: :environment do |_t, args|
    args.extras.each do |tuple|
      key, value = tuple.split('=')
      setting = Setting.find_by(name: key)
      if setting.nil?
        Setting.create! name: key, value: value
      else
        setting.update_attributes! value: value
      end
    end
  end

  desc 'Allow to get a Setting: rake setting:get[key]'
  task :get, [:key] => :environment do |_t, args|
    setting = Setting.find_by(name: args[:key])
    unless setting.nil?
      puts(setting.value)
    end
  end
end
