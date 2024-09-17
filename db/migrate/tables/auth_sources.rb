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

require_relative "base"

class Tables::AuthSources < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.string :type, limit: 30, default: "", null: false
      t.string :name, limit: 60, default: "", null: false
      t.string :host, limit: 60
      t.integer :port
      t.string :account
      t.string :account_password, default: ""
      t.string :base_dn
      t.string :attr_login, limit: 30
      t.string :attr_firstname, limit: 30
      t.string :attr_lastname, limit: 30
      t.string :attr_mail, limit: 30
      t.boolean :onthefly_register, default: false, null: false
      t.boolean :tls, default: false, null: false
      t.string :attr_admin

      t.index %i[id type], name: "index_auth_sources_on_id_and_type"
    end
  end
end
