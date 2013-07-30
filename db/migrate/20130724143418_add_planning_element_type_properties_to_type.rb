class AddPlanningElementTypePropertiesToType < ActiveRecord::Migration

  # create_table "planning_element_types", :force => true do |t|
  #   t.string   "name",                              :null => false
  #   t.boolean  "in_aggregation", :default => true,  :null => false
  #   t.boolean  "is_milestone",   :default => false, :null => false
  #   t.boolean  "is_default",     :default => false, :null => false
  #   t.integer  "position",       :default => 1
  #   t.integer  "color_id"
  #   t.datetime "created_at",                        :null => false
  #   t.datetime "updated_at",                        :null => false
  # end

  # add_index "planning_element_types", ["color_id"], :name => "index_timelines_planning_element_types_on_color_id"

  # create_table "types", :force => true do |t|
  #   t.string  "name",          :limit => 30, :default => "",    :null => false
  #   t.boolean "is_in_chlog",                 :default => false, :null => false
  #   t.integer "position",                    :default => 1
  #   t.boolean "is_in_roadmap",               :default => true,  :null => false
  # end

  def up

    add_column :types, :in_aggregation, :boolean, :default => true,  :null => false
    add_column :types, :is_milestone,   :boolean, :default => false, :null => false
    add_column :types, :is_default,     :boolean, :default => false, :null => false

    add_column :types, :color_id,   :integer
    add_column :types, :created_at, :datetime, :null => false
    add_column :types, :updated_at, :datetime, :null => false

    change_column :types, :name, :string, :default => "", :null => false

    add_index :types, [:color_id], :name => :index_types_on_color_id

  end

  def down

    remove_column :types, :in_aggregation
    remove_column :types, :is_milestone
    remove_column :types, :is_default

    remove_column :types, :color_id
    remove_column :types, :created_at
    remove_column :types, :updated_at

    change_column :types, :name, :string, :limit => 30, :default => "", :null => false

    remove_index :types, :name => :index_types_on_color_id
  end

end
