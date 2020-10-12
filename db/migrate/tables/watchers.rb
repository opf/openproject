#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_relative 'base'

class Tables::Watchers < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.string :watchable_type, default: '', null: false
      t.integer :watchable_id, default: 0, null: false
      t.integer :user_id

      t.index %i(user_id watchable_type), name: 'watchers_user_id_type'
      t.index :user_id, name: 'index_watchers_on_user_id'
      t.index %i(watchable_id watchable_type), name: 'index_watchers_on_watchable_id_and_watchable_type'
    end
  end
end
