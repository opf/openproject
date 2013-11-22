#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require Rails.root.join("db","migrate","migration_utils","utils").to_s

class LegacyIssuesCostsDataToWorkPackages < ActiveRecord::Migration

  def up
    return unless migration_applicable?

    execute <<-SQL
      UPDATE work_packages
      SET cost_object_id = (SELECT legacy_issues.cost_object_id
                            FROM legacy_issues
                            WHERE legacy_issues.id = work_packages.id
                            LIMIT 1)
    SQL
  end

  def down
    return unless migration_applicable?

    execute <<-SQL
      UPDATE legacy_issues
      SET cost_object_id = (SELECT work_packages.cost_object_id
                            FROM work_packages
                            WHERE work_packages.id = legacy_issues.id
                            LIMIT 1)
    SQL
  end

  private

  def migration_applicable?
    ActiveRecord::Base.connection.table_exists?('legacy_issues') &&
    ActiveRecord::Base.connection.columns('legacy_issues').map(&:name).include?('cost_object_id')
  end
end
