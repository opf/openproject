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

class CreateUserPasswords < ActiveRecord::Migration[4.2]
  def initialize(*)
    super
    @former_passwords_table_exists = ActiveRecord::Base.connection.tables.include? 'former_user_passwords'
  end

  def up
    create_table :user_passwords do |t|
      t.integer :user_id, null: false
      t.string :hashed_password, limit: 40
      t.string :salt, limit: 64
      t.timestamps
    end
    add_index :user_passwords, :user_id

    # if the plugin strong passwords was installed, we also transfer its
    # stored former passwords of the users
    if @former_passwords_table_exists
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO user_passwords (user_id, hashed_password, salt, created_at, updated_at)
        SELECT user_id, hashed_password, salt, created_at, updated_at FROM former_user_passwords
        ORDER BY id
      SQL
      drop_table :former_user_passwords
    end

    begin
      # because of the circular dependencies between User, Principal and Project
      # we have to require principal first
      # see https://community.openproject.org/work_packages/1294
      require 'principal'
      UserPassword.record_timestamps = false
      # Create a UserPassword with the old password for each user
      User.find_each do |user|
        user.passwords.create(hashed_password: user.hashed_password,
                              salt: user.salt,
                              created_at: user.updated_on,
                              updated_at: user.updated_on)
      end
    ensure
      UserPassword.record_timestamps = true
    end

    change_table :users do |t|
      t.remove :hashed_password, :salt
    end
    User.reset_column_information
  end

  def down
    # we dont recreate the former_user_passwords_table here, since there is no Rails3
    # version of the old strong passwords plugin
    change_table :users do |t|
      t.string :hashed_password, limit: 40
      t.string :salt, limit: 60
    end
    User.reset_column_information

    begin
      User.record_timestamps = false
      User.find_each do |user|
        password = user.send(:current_password)
        user.hashed_password = password.hashed_password
        user.salt = password.salt
        user.save
      end
    ensure
      User.record_timestamps = false
    end

    drop_table :user_passwords
  end
end
