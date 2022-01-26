class RemoveSnapshotData < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      UPDATE bcf_viewpoints
      SET json_viewpoint = json_viewpoint #- '{snapshot,snapshot_data}';
    SQL
  end

  def down
    # removed snapshot data cannot be restored
  end
end
