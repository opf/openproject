require_relative "migration_utils/utils"

class EnableGanttModuleForAllProjects < ActiveRecord::Migration[7.0]
  include ::Migration::Utils

  def up
    execute_sql "
      INSERT INTO enabled_modules (project_id, name)
      SELECT id, 'gantt' FROM projects
      WHERE id NOT IN (SELECT project_id FROM enabled_modules WHERE name = 'gantt')
      AND id IN (SELECT project_id FROM enabled_modules WHERE name = 'work_package_tracking')
      AND active;
     "
  end

  def down
    execute_sql "DELETE FROM enabled_modules WHERE name = 'gantt'"
  end
end
