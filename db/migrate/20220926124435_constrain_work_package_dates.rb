class ConstrainWorkPackageDates < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        WorkPackage.where("start_date > due_date").in_batches.each_record do |work_package|
          User.execute_as(User.system) do
            work_package.start_date = work_package.due_date
            work_package.duration = 1
            work_package.journal_notes = '_Resetting the start date automatically to fix inconsistent dates._'
            work_package.save!(validate: false)
          end
        end
      end
    end

    add_check_constraint :work_packages, 'due_date >= start_date', name: 'work_packages_due_larger_start_date'
  end
end
