class AddIncludeSubprojectsToQuery < ActiveRecord::Migration[6.1]
  def change
    add_column :queries,
               :include_subprojects,
               :boolean,
               null: false,
               default: Setting.display_subprojects_work_packages?

    # Remove the default now
    reversible do |dir|
      dir.up { change_column_default :queries, :include_subprojects, nil }
    end
  end
end
