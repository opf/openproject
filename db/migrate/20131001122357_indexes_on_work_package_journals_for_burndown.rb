class IndexesOnWorkPackageJournalsForBurndown < ActiveRecord::Migration
  def change
    add_index :work_package_journals, [:fixed_version_id,
                                       :status_id,
                                       :project_id,
                                       :type_id],
                                      :name => 'work_package_journal_on_burndown_attributes'
  end
end
