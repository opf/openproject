#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class CreateUserPasswords < ActiveRecord::Migration
  def up
    create_table :user_passwords do |t|
      t.integer :user_id, :null => false
      t.string :hashed_password, :limit => 40
      t.string :salt, :limit => 64
      t.timestamps
    end
    add_index :user_passwords, :user_id

    begin
      # because of the circular dependencies between User, Principal and Project
      # we have to require principal first
      # see https://www.openproject.org/issues/1294
      require 'principal'
      UserPassword.record_timestamps = false
      # Create a UserPassword with the old password for each user
      User.find_each do |user|
        user.passwords.create({:hashed_password => user.hashed_password,
                               :salt => user.salt,
                               :created_at => user.updated_on,
                               :updated_at => user.updated_on})
      end
    ensure
      UserPassword.record_timestamps = true
    end

    change_table :users do |t|
      t.remove :hashed_password, :salt
    end
  end

  def down
    change_table :users do |t|
      t.string :hashed_password, :limit => 40
      t.string :salt, :limit => 60
    end

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
