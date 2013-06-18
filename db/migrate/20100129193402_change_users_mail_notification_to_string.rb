#-- encoding: UTF-8
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

class ChangeUsersMailNotificationToString < ActiveRecord::Migration
  def self.up
    rename_column :users, :mail_notification, :mail_notification_bool
    add_column :users, :mail_notification, :string, :default => '', :null => false
    User.update_all("mail_notification = 'all'", "mail_notification_bool = #{connection.quoted_true}")
    User.update_all("mail_notification = 'selected'", "EXISTS (SELECT 1 FROM #{Member.table_name} WHERE #{Member.table_name}.mail_notification = #{connection.quoted_true} AND #{Member.table_name}.user_id = #{User.table_name}.id)")
    User.update_all("mail_notification = 'only_my_events'", "mail_notification NOT IN ('all', 'selected')")
    remove_column :users, :mail_notification_bool
  end

  def self.down
    rename_column :users, :mail_notification, :mail_notification_char
    add_column :users, :mail_notification, :boolean, :default => true, :null => false
    User.update_all("mail_notification = #{connection.quoted_false}", "mail_notification_char <> 'all'")
    remove_column :users, :mail_notification_char
  end
end
