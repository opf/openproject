ActiveRecord::Schema.define do

  create_table "users", :force => true do |t|
    t.column "name",       :text
    t.column "salary",     :integer,  :default => 70000
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "type",       :text
  end

  create_table "projects", :force => true do |t|
    t.column "name", :text
  end

  create_table "developers_projects", :id => false, :force => true do |t|
    t.column "developer_id", :integer, :null => false
    t.column "project_id",   :integer, :null => false
    t.column "joined_on",    :date
    t.column "access_level", :integer, :default => 1
  end

  create_table "topics", :force => true do |t|
    t.column "project_id", :integer
    t.column "title",      :string
    t.column "subtitle",   :string
    t.column "content",    :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "replies", :force => true do |t|
    t.column "content",    :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "topic_id",   :integer
  end

end
