class Setup < ActiveRecord::Migration
  def self.up
    create_table "attachments", :force => true do |t|
      t.column "container_id", :integer, :default => 0, :null => false
      t.column "container_type", :string, :limit => 30, :default => "", :null => false
      t.column "filename", :string, :default => "", :null => false
      t.column "disk_filename", :string, :default => "", :null => false
      t.column "size", :integer, :default => 0, :null => false
      t.column "content_type", :string, :limit => 60, :default => "", :null => false
      t.column "digest", :string, :limit => 40, :default => "", :null => false
      t.column "downloads", :integer, :default => 0, :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
    end
  
    create_table "custom_fields", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "typ", :integer, :limit => 6, :default => 0, :null => false
      t.column "is_required", :boolean, :default => false, :null => false
      t.column "is_for_all", :boolean, :default => false, :null => false
      t.column "possible_values", :text, :default => "", :null => false
      t.column "regexp", :string, :default => "", :null => false
      t.column "min_length", :integer, :limit => 4, :default => 0, :null => false
      t.column "max_length", :integer, :limit => 4, :default => 0, :null => false
    end
  
    create_table "custom_fields_projects", :id => false, :force => true do |t|
      t.column "custom_field_id", :integer, :default => 0, :null => false
      t.column "project_id", :integer, :default => 0, :null => false
    end
  
    create_table "custom_values", :force => true do |t|
      t.column "issue_id", :integer, :default => 0, :null => false
      t.column "custom_field_id", :integer, :default => 0, :null => false
      t.column "value", :text, :default => "", :null => false
    end
  
    add_index "custom_values", ["issue_id"], :name => "custom_values_issue_id"
 
    create_table "documents", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "category_id", :integer, :default => 0, :null => false
      t.column "title", :string, :limit => 60, :default => "", :null => false
      t.column "descr", :text, :default => "", :null => false
      t.column "created_on", :timestamp
    end
  
    create_table "enumerations", :force => true do |t|
      t.column "opt", :string, :limit => 4, :default => "", :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
    end
  
    create_table "issue_categories", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
    end
  
    create_table "issue_histories", :force => true do |t|
      t.column "issue_id", :integer, :default => 0, :null => false
      t.column "status_id", :integer, :default => 0, :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "notes", :text, :default => "", :null => false
      t.column "created_on", :timestamp
    end
  
    add_index "issue_histories", ["issue_id"], :name => "issue_histories_issue_id"

    create_table "issue_statuses", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "is_closed", :boolean, :default => false, :null => false
      t.column "is_default", :boolean, :default => false, :null => false
      t.column "html_color", :string, :limit => 6, :default => "FFFFFF", :null => false
    end
  
    create_table "issues", :force => true do |t|
      t.column "tracker_id", :integer, :default => 0, :null => false
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "subject", :string, :default => "", :null => false
      t.column "descr", :text, :default => "", :null => false
      t.column "category_id", :integer
      t.column "status_id", :integer, :default => 0, :null => false
      t.column "assigned_to_id", :integer
      t.column "priority_id", :integer, :default => 0, :null => false
      t.column "fixed_version_id", :integer
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    add_index "issues", ["project_id"], :name => "issues_project_id"
  
    create_table "members", :force => true do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
    end
  
    create_table "news", :force => true do |t|
      t.column "project_id", :integer
      t.column "title", :string, :limit => 60, :default => "", :null => false
      t.column "shortdescr", :string, :default => "", :null => false
      t.column "descr", :text, :default => "", :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
    end
  
    create_table "permissions", :force => true do |t|
      t.column "controller", :string, :limit => 30, :default => "", :null => false
      t.column "action", :string, :limit => 30, :default => "", :null => false
      t.column "descr", :string, :limit => 60, :default => "", :null => false
      t.column "public", :boolean, :default => false, :null => false
      t.column "sort", :integer, :default => 0, :null => false
      t.column "mail_option", :boolean, :default => false, :null => false
      t.column "mail_enabled", :boolean, :default => false, :null => false
    end
  
    create_table "permissions_roles", :id => false, :force => true do |t|
      t.column "permission_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
    end
  
    add_index "permissions_roles", ["role_id"], :name => "permissions_roles_role_id"
  
    create_table "projects", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "descr", :string, :default => "", :null => false
      t.column "homepage", :string, :limit => 60, :default => "", :null => false
      t.column "public", :boolean, :default => true, :null => false
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    create_table "roles", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
    end
  
    create_table "trackers", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "is_in_chlog", :boolean, :default => false, :null => false
    end
  
    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 30, :default => "", :null => false
      t.column "hashed_password", :string, :limit => 40, :default => "", :null => false
      t.column "firstname", :string, :limit => 30, :default => "", :null => false
      t.column "lastname", :string, :limit => 30, :default => "", :null => false
      t.column "mail", :string, :limit => 60, :default => "", :null => false
      t.column "mail_notification", :boolean, :default => true, :null => false
      t.column "admin", :boolean, :default => false, :null => false
      t.column "locked", :boolean, :default => false, :null => false
      t.column "last_login_on", :datetime
      t.column "language", :string, :limit => 2, :default => "", :null => false
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    create_table "versions", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "descr", :string, :default => "", :null => false
      t.column "date", :date, :null => false
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    create_table "workflows", :force => true do |t|
      t.column "tracker_id", :integer, :default => 0, :null => false
      t.column "old_status_id", :integer, :default => 0, :null => false
      t.column "new_status_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
    end
  
    # project
    Permission.create :controller => "projects", :action => "show", :descr => "Overview", :sort => 100, :public => true
    Permission.create :controller => "projects", :action => "changelog", :descr => "View change log", :sort => 105, :public => true
    Permission.create :controller => "reports", :action => "issue_report", :descr => "View reports", :sort => 110, :public => true
    Permission.create :controller => "projects", :action => "settings", :descr => "Settings", :sort => 150
    Permission.create :controller => "projects", :action => "edit", :descr => "Edit", :sort => 151
    # members
    Permission.create :controller => "projects", :action => "list_members", :descr => "View list", :sort => 200, :public => true
    Permission.create :controller => "projects", :action => "add_member", :descr => "New member", :sort => 220
    Permission.create :controller => "members", :action => "edit", :descr => "Edit", :sort => 221
    Permission.create :controller => "members", :action => "destroy", :descr => "Delete", :sort => 222
    # versions
    Permission.create :controller => "projects", :action => "add_version", :descr => "New version", :sort => 320
    Permission.create :controller => "versions", :action => "edit", :descr => "Edit", :sort => 321
    Permission.create :controller => "versions", :action => "destroy", :descr => "Delete", :sort => 322
    # issue categories
    Permission.create :controller => "projects", :action => "add_issue_category", :descr => "New issue category", :sort => 420
    Permission.create :controller => "issue_categories", :action => "edit", :descr => "Edit", :sort => 421
    Permission.create :controller => "issue_categories", :action => "destroy", :descr => "Delete", :sort => 422
    # issues
    Permission.create :controller => "projects", :action => "list_issues", :descr => "View list", :sort => 1000, :public => true
    Permission.create :controller => "issues", :action => "show", :descr => "View", :sort => 1005, :public => true
    Permission.create :controller => "issues", :action => "download", :descr => "Download file", :sort => 1010, :public => true
    Permission.create :controller => "projects", :action => "add_issue", :descr => "Report an issue", :sort => 1050, :mail_option => 1, :mail_enabled => 1
    Permission.create :controller => "issues", :action => "edit", :descr => "Edit", :sort => 1055
    Permission.create :controller => "issues", :action => "change_status", :descr => "Change status", :sort => 1060, :mail_option => 1, :mail_enabled => 1
    Permission.create :controller => "issues", :action => "destroy", :descr => "Delete", :sort => 1065
    Permission.create :controller => "issues", :action => "add_attachment", :descr => "Add file", :sort => 1070
    Permission.create :controller => "issues", :action => "destroy_attachment", :descr => "Delete file", :sort => 1075
    # news
    Permission.create :controller => "projects", :action => "list_news", :descr => "View list", :sort => 1100, :public => true
    Permission.create :controller => "news", :action => "show", :descr => "View", :sort => 1101, :public => true
    Permission.create :controller => "projects", :action => "add_news", :descr => "Add", :sort => 1120
    Permission.create :controller => "news", :action => "edit", :descr => "Edit", :sort => 1121
    Permission.create :controller => "news", :action => "destroy", :descr => "Delete", :sort => 1122
    # documents
    Permission.create :controller => "projects", :action => "list_documents", :descr => "View list", :sort => 1200, :public => true
    Permission.create :controller => "documents", :action => "show", :descr => "View", :sort => 1201, :public => true
    Permission.create :controller => "documents", :action => "download", :descr => "Download", :sort => 1202, :public => true
    Permission.create :controller => "projects", :action => "add_document", :descr => "Add", :sort => 1220
    Permission.create :controller => "documents", :action => "edit", :descr => "Edit", :sort => 1221
    Permission.create :controller => "documents", :action => "destroy", :descr => "Delete", :sort => 1222
    Permission.create :controller => "documents", :action => "add_attachment", :descr => "Add file", :sort => 1223
    Permission.create :controller => "documents", :action => "destroy_attachment", :descr => "Delete file", :sort => 1224
    # files
    Permission.create :controller => "projects", :action => "list_files", :descr => "View list", :sort => 1300, :public => true
    Permission.create :controller => "versions", :action => "download", :descr => "Download", :sort => 1301, :public => true
    Permission.create :controller => "projects", :action => "add_file", :descr => "Add", :sort => 1320
    Permission.create :controller => "versions", :action => "destroy_file", :descr => "Delete", :sort => 1322
    
    # create default administrator account
    user = User.create :login => "admin", :password => "admin", :firstname => "redMine", :lastname => "Admin", :mail => "admin@somenet.foo", :mail_notification => true, :language => "en"
    user.admin = true
    user.save
    
    
  end

  def self.down
    drop_table :attachments
    drop_table :custom_fields
    drop_table :custom_fields_projects
    drop_table :custom_values
    drop_table :documents
    drop_table :enumerations
    drop_table :issue_categories
    drop_table :issue_histories
    drop_table :issue_statuses
    drop_table :issues
    drop_table :members
    drop_table :news
    drop_table :permissions
    drop_table :permissions_roles
    drop_table :projects
    drop_table :roles
    drop_table :trackers
    drop_table :users
    drop_table :versions
    drop_table :workflows
  end
end
