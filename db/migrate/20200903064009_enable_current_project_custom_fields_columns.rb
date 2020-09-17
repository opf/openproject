class EnableCurrentProjectCustomFieldsColumns < ActiveRecord::Migration[6.0]
  def up
    columns = Setting.enabled_projects_columns
    cf_columns = ProjectCustomField.pluck(:id).map { |id| "cf_#{id}" }

    Setting.enabled_projects_columns = (columns + cf_columns).uniq
  end

  def down
    # Nothing to do as setting is not used
  end
end
