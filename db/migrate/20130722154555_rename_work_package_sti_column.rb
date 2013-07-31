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

class RenameWorkPackageStiColumn < ActiveRecord::Migration
  def up
    rename_column :work_packages, :type, :sti_type
  end

  def down
    rename_column :work_packages, :sti_type, :type
  end
end
