# frozen_string_literal: true

class BackfillTargetVersionsFromWorkPackage < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Copying work_packages.version_id into work_package_associated_versions (kind: target)" do
      execute <<~SQL.squish
        INSERT INTO work_package_versions (work_package_id, version_id, kind, created_at, updated_at)
            SELECT work_packages.id, work_packages.version_id, 'target', now(), now()
            FROM work_packages
            INNER JOIN versions ON versions.id = work_packages.version_id
            WHERE work_packages.version_id IS NOT NULL
        ON CONFLICT (work_package_id, version_id, kind) DO NOTHING
      SQL
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
