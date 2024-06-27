class AddIncludeAllMembersAssignedProjectsToQuery < ActiveRecord::Migration[7.1]
  def change
    add_column :queries,
               :include_all_members_assigned_projects,
               :boolean,
               null: false,
               default: false
  end
end
