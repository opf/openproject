# frozen_string_literal: true

class BackfillCategoriesFromWorkPackage < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Copying work_packages.category_id into work_package_categories" do
      execute <<~SQL.squish
        INSERT INTO work_package_categories (work_package_id, category_id, created_at, updated_at)
            SELECT work_packages.id, work_packages.category_id, now(), now()
            FROM work_packages
            INNER JOIN categories ON categories.id = work_packages.category_id
            WHERE work_packages.category_id IS NOT NULL
        ON CONFLICT (work_package_id, category_id) DO NOTHING
      SQL
    end
  end

  def down
    # The join rows are redundant with work_packages.category_id for as long as
    # the deprecated column is mirrored, so there is nothing to restore.
  end
end
