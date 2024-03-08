class AddGanttModuleToDefaultModules < ActiveRecord::Migration[7.0]
  def up
    unless Setting.default_projects_modules.include?("gantt")
      Setting.default_projects_modules = Setting.default_projects_modules + ["gantt"]
    end
  end

  def down
    # Nothing to do
  end
end
