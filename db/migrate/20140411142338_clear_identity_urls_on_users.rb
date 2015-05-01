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

class ClearIdentityUrlsOnUsers < ActiveRecord::Migration
  def up
    create_table 'legacy_user_identity_urls' do |t|
      t.string 'login', limit: 256, default: '',    null: false
      t.string 'identity_url'
    end

    execute "INSERT INTO legacy_user_identity_urls(id, login, identity_url)
             SELECT id, login, identity_url FROM users"

    execute 'UPDATE users SET identity_url = NULL'
  end

  def down
    if mysql?

      execute "UPDATE users u
               JOIN legacy_user_identity_urls lu ON u.id = lu.id
               SET u.identity_url = lu.identity_url"

    elsif postgres?

      execute "UPDATE users
               SET identity_url = lu.identity_url
               FROM legacy_user_identity_urls lu
               WHERE users.id = lu.id"

    else
      raise 'The down part of this migration only supports MySQL and PostgreSQL.'
    end

    drop_table :legacy_user_identity_urls
  end

  def postgres?
    ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
  end

  def mysql?
    ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'mysql2'
  end
end
