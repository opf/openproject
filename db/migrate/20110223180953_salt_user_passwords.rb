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
      User.salt_unsalted_passwords!
    end
  end

  def self.down
    # Unsalted passwords can not be restored
    raise ActiveRecord::IrreversibleMigration, "Can't decypher salted passwords. This migration can not be rollback'ed."
  end
end
