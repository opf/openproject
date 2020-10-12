class AddUniquenessContrainToBcfTopicOnUuid < ActiveRecord::Migration[6.0]
  def up
    # Create unique index on an issue's uuid. A BCF issue should only exist once on an instance. If you need a copy,
    # then it is not the same anymore and thus should have a different uuid.
    remove_index :bcf_issues, :uuid
    add_index :bcf_issues, %i[uuid], unique: true
  end

  def down
    remove_index :bcf_issues, :uuid
    add_index :bcf_issues, %i[uuid]
  end
end
