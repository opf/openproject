#-- encoding: UTF-8

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

class Tables::Users < Tables::Base
  # rubocop:disable Metrics/AbcSize
  def self.table(migration)
    create_table migration do |t|
      t.string :login, limit: 256, default: '', null: false
      t.string :firstname, limit: 30, default: '', null: false
      t.string :lastname, limit: 30, default: '', null: false
      t.string :mail, limit: 60, default: '', null: false
      t.boolean :admin, default: false, null: false
      t.integer :status, default: 1, null: false
      t.datetime :last_login_on
      t.string :language, limit: 5, default: ''
      t.integer :auth_source_id
      t.datetime :created_on
      t.datetime :updated_on
      t.string :type
      t.string :identity_url
      t.string :mail_notification, default: '', null: false
      t.boolean :first_login, null: false, default: true
      t.boolean :force_password_change, default: false
      t.integer :failed_login_count, default: 0
      t.datetime :last_failed_login_on, null: true

      t.index %i[auth_source_id], name: 'index_users_on_auth_source_id'
      t.index %i[id type], name: 'index_users_on_id_and_type'
      t.index %i[type], name: 'index_users_on_type'
      t.index %i[type login], length: { type: 255, login: 255 }
      t.index %i[type status]
    end
  end
  # rubocop:enable Metrics/AbcSize
end
