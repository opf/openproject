class AddGanttModuleToDefaultModules < ActiveRecord::Migration[7.0]
  def up
    if Setting.default_projects_modules_writable? && Setting.default_projects_modules&.exclude?("gantt")
      Setting.default_projects_modules = Setting.default_projects_modules + ["gantt"]
    end
  end

  def down
    # Nothing to do
  end
end
