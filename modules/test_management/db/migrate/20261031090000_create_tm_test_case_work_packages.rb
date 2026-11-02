# frozen_string_literal: true

# Many-to-many link between test cases and work packages (one case can cover
# many work packages, one work package can be covered by many cases).
class CreateTmTestCaseWorkPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_test_case_work_packages do |t|
      t.references :test_case,
                   null: false,
                   index: true,
                   foreign_key: { to_table: :tm_test_cases, on_delete: :cascade }
      t.references :work_package,
                   null: false,
                   index: true,
                   foreign_key: { on_delete: :cascade }
      t.timestamps null: false
    end

    add_index :tm_test_case_work_packages,
              %i[test_case_id work_package_id],
              unique: true,
              name: "index_tm_test_case_wps_on_case_and_wp"
  end
end
