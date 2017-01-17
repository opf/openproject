#-- encoding: UTF-8
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

class SettingValueToHash < ActiveRecord::Migration[5.0]
  class SettingWithWhatever < ActiveRecord::Base
    self.table_name = :settings

    serialize :value
  end

  class SettingWithHash < ActiveRecord::Base
    self.table_name = :settings

    serialize :value, Hash
  end

  def up
    SettingWithWhatever.transaction do
      SettingWithWhatever.all.to_a.each do |setting|
        value = setting.value
        next unless value && value.is_a?(ActionController::Parameters)
        value.permit!
        value = value.to_h

        SettingWithHash
          .where(id: setting.id)
          .update_all(value: value)
      end
    end
  end

  # This migration does not need to be rolled back because
  # it only harmonizes the possible values of the value attribute.
end
