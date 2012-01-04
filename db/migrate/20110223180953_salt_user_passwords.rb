#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
