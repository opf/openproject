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

require_relative 'migration_utils/utils'

class LegacyIssuesToWorkPackages < ActiveRecord::Migration

  def up
    execute <<-SQL
      UPDATE work_packages
      SET cost_object_id = (SELECT legacy_issues.cost_object_id
                            FROM legacy_issues
                            WHERE legacy_issues.id = work_packages.id
                            LIMIT 1)
    SQL
  end

  def down
    execute <<-SQL
      UPDATE legacy_issues
      SET cost_object_id = (SELECT work_packages.cost_object_id
                            FROM work_packages
                            WHERE work_packages.id = legacy_issues.id
                            LIMIT 1)
    SQL
  end
end
