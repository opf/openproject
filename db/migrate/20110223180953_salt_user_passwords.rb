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

class SaltUserPasswords < ActiveRecord::Migration

  def self.up
    say_with_time "Salting user passwords, this may take some time..." do
      User.find_each(:conditions => "salt IS NULL OR salt = ''") do |user|
        next if user.hashed_password.blank?
        salt = SecureRandom.hex(16)
        hashed_password = Digest::SHA1.hexdigest("#{salt}#{user.hashed_password}")
        User.update_all("salt = '#{salt}', hashed_password = '#{hashed_password}'", ["id = ?", user.id] )
      end
    end
  end

  def self.down
    # Unsalted passwords can not be restored
    raise ActiveRecord::IrreversibleMigration, "Can't reverse hashing of passwords. This migration can not be rolled back."
  end
end
