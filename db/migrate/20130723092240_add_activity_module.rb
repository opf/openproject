class AddActivityModule < ActiveRecord::Migration
  def up
    # activate activity module for all projects
    Project.all.each do |project|
      project.enabled_module_names = ["activity"] | project.enabled_module_names
    end

    # add activity module from default settings
    Setting["default_projects_modules"] = ["activity"] | Setting.default_projects_modules
  end

  def down
    # deactivate activity module for all projects
    Project.all.each do |project|
      project.enabled_module_names = project.enabled_module_names - ["activity"]
    end

    # remove activity module from default settings
    Setting["default_projects_modules"] = Setting.default_projects_modules - ["activity"]
  end
end
