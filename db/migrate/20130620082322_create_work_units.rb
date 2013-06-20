class CreateWorkUnits < ActiveRecord::Migration
  def up
    create_table "work_units" do |t|
      # Issue
      t.column :tracker_id, :integer, :default => 0, :null => false
      t.column :project_id, :integer
      t.column :subject, :string, :default => "", :null => false
      t.column :description, :text
      t.column :due_date, :date
      t.column :category_id, :integer
      t.column :status_id, :integer, :default => 0, :null => false
      t.column :assigned_to_id, :integer
      t.column :priority_id, :integer, :default => 0, :null => false
      t.column :fixed_version_id, :integer
      t.column :author_id, :integer, :default => 0, :null => false
      t.column :lock_version, :integer, :default => 0, :null => false
      t.column :done_ratio, :integer, :default => 0, :null => false
      t.column :estimated_hours, :float
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp

      # Planning Element
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :planning_element_status_comment, :text
      t.column :deleted_at, :datetime

      t.belongs_to :parent
      t.belongs_to :project
      t.belongs_to :responsible
      t.belongs_to :planning_element_type
      t.belongs_to :planning_element_status

      # STI
      t.column :type, :string

      # Nested Set
      t.column :parent_id, :integer, :default => nil
      t.column :root_id, :integer, :default => nil
      t.column :lft, :integer, :default => nil
      t.column :rgt, :integer, :default => nil
    end

    # Issue compatibility
    # Because of 't.belongs_to :project' (see above) column 'project_id'
    # becomes nullable. That breaks compatibility with issue behavior.
    change_table "work_units" do |t|
      t.change :project_id, :integer, :default => 0, :null => false
    end

    # Planning Elements
    add_index :work_units, :parent_id
    add_index :work_units, :project_id
    add_index :work_units, :responsible_id
    add_index :work_units, :planning_element_type_id
    add_index :work_units, :planning_element_status_id

    # Nested Set
    add_index :work_units, [:root_id, :lft, :rgt]

    change_table(:projects) do |t|
      t.belongs_to :work_units_responsible

      t.index :work_units_responsible_id
    end
  end

  def down
    change_table(:projects) do |t|
      t.remove_belongs_to :work_units_responsible
    end

    drop_table(:work_units)
  end
end
